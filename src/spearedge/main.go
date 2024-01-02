package main

import (
	"bytes"
   "fmt"
   "net/http"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	corev1 "k8s.io/api/core/v1"
   "k8s.io/client-go/kubernetes"
   "k8s.io/client-go/rest"
   "os"
   "log"
   "context"
   "io/ioutil"
   "encoding/json"
   "time"
   "crypto/rand"
   "strconv"
)

const podIDChars = "1234567890abcdefghi"

func GeneratePodid(length int)(string , error) {

	buffer := make([]byte, length)
	_ ,err := rand.Read(buffer)
	if err != nil {
		return "", err
	}

	podIDCharLength := len(podIDChars)
	for i := 0; i < length; i++ {
		buffer[i] = podIDChars[int(buffer[i])%podIDCharLength]
	}

	return string(buffer), nil

}

type SendInput struct {
	Port string `json:"port"`
	Target string `json:"target"`
	Protocol string `json:"protocol"`
}

type Postinput struct {
	Port string `json:"port"`
	Target string `json:"target"`
	Protocol string `json:"protocol"`
	Hostname string `json:hostname`
}

type Postoutput struct {
	Status string `json:"status"`
	Message string `json:"message"`
}

func intro(w http.ResponseWriter, r *http.Request ) {

	fmt.Fprintf(w, "For testing add '/checkport' or '/listnodes' to the URL\n")
	fmt.Fprintf(os.Stdout,"For testing add '/checkport' or '/listnodes' to the URL\n")
	return
}

func listnodes(w http.ResponseWriter, r *http.Request) {

	// login to kubernetes with the service account credentials

	config , err := rest.InClusterConfig()

	if err != nil {
		panic(err.Error())
	}

	// create a clientset

	clientset , err := kubernetes.NewForConfig(config)

	if err != nil {
		panic(err.Error())
	}


	// deploy a pod with a nodeselector

	fmt.Fprintf(os.Stdout, "successfully login with cluster service account\n")
  
   // list the node in the cluster 
	
	nodeList , err := clientset.CoreV1().Nodes().List(context.Background(), metav1.ListOptions{})

	if err != nil {
		fmt.Fprintf(w, "Unable to List nodes on the Cluster", http.StatusBadRequest)
		panic(err)
	}

	for _ , n := range nodeList.Items {
		fmt.Fprintf(w, "Node : %s\n", n.Name)
	}
	// deploy a pod with a nodeselector
}

func checkport(w http.ResponseWriter, r *http.Request) {


	config , err := rest.InClusterConfig()

	if err != nil {
		panic(err.Error())
	}

	// create a clientset

	clientset , err := kubernetes.NewForConfig(config)

	if err != nil {
		panic(err.Error())
	}


	if r.URL.Path != "/checkport" {
		http.Error(w,"the Provided URL is not valid", http.StatusBadRequest)
		fmt.Fprintf(os.Stderr, "The Provided URL is not valid\n")
	}

	if r.Method != "POST" {
		http.Error(w, "the HTTP method must be POST", http.StatusBadRequest)
		fmt.Fprintf(os.Stderr, "The HTTP Method must be POST, not %s\n", r.Method)
	}

		var Body []byte
	if r.Body != nil {
		if data , err := ioutil.ReadAll(r.Body); err == nil {
			Body = data

		//	fmt.Fprintf(os.Stdout,"the Body was received\n")
		//	fmt.Fprintf(w,"the Body was received\n")

		} else {
			fmt.Fprintf(os.Stderr, "Unable to Copy the Body\n")
			return
		}
	}

	

	if len(Body) == 0 {
		fmt.Fprintf(os.Stderr, "Unable to retrieve Body\n")
		http.Error(w, "Unable to retrieve Body", http.StatusBadRequest)
		return
	}
    
    var input Postinput

     if err := json.Unmarshal(Body, &input); err != nil {
    	 
    	 fmt.Fprintf(os.Stderr, "Unable to unmarshal the Body\n")
    	 http.Error(w, "Unable to unmarshal the Body", http.StatusBadRequest)
    	 return
    } else {

    	 fmt.Fprintf(os.Stderr, "%+v\n", input)

    }

    hostname := input.Hostname

    podNs , found := os.LookupEnv("DST_NAMESPACE")

    if !found {
    	podNs = "port-check"
    }

    podImage , found := os.LookupEnv("POD_IMAGE")

    if !found {
    	podImage = "portcheck:latest"
    }

	pod_name , err := GeneratePodid(6)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Unable to Generate Pod Name\n")
    	http.Error(w, "Unable to Generate Pod Name", http.StatusBadRequest)
    	return
	}    

    pod_name = "portcheck-" + pod_name

    newPod := &corev1.Pod{
   	ObjectMeta: metav1.ObjectMeta{
   		Name: pod_name,
   	},
   	Spec: corev1.PodSpec{
   		Containers: []corev1.Container{
   			{Name: pod_name, Image: podImage, },
   		},
   		NodeName: hostname,
   	},
   }

   _ , err = clientset.CoreV1().Pods(podNs).Create(context.Background(), newPod ,metav1.CreateOptions{})

   if err != nil {
   	panic(err)
   }
   
   // wait X second for the pod to start

   interval := 10
   interval_time, ierr := os.LookupEnv("INTERVAL_TIME")

   if ierr {
   	interval , err = strconv.Atoi(interval_time)
   }

   time.Sleep(time.Duration(interval) * time.Second)

   pods , err := clientset.CoreV1().Pods(podNs).List(context.TODO(), metav1.ListOptions{})

   if err != nil {
   	panic(err)
   }

   podIP := "none"

   podloop:for _ , pod := range pods.Items {
   	if pod.Name == pod_name {
   		podIP = pod.Status.PodIP
   		break podloop

   	} 
   }

   if podIP == "none" {  	
   	fmt.Fprintf(os.Stderr, "Unable to Obtain Pod IP Address\n")
    	http.Error(w, "Unable to Obtain Pod IP Address", http.StatusBadRequest)
    	return
   }

   var jsonData SendInput

   jsonData.Port = input.Port
   jsonData.Target = input.Target
   jsonData.Protocol = input.Protocol

   podIP = "http://" + podIP + ":8080/portcheck"

   fmt.Fprintf(os.Stdout, "the Pod URL is :%s\n", podIP)

   sendBody, _ := json.Marshal(jsonData)

   response, error := http.Post(podIP,  "application/json", bytes.NewBuffer(sendBody)) 

	if error != nil {
		panic(error)
	}

	defer response.Body.Close()

	if response.StatusCode == http.StatusOK {
		body , err := ioutil.ReadAll(response.Body)

		if err != nil {
			panic(err)
		}

		fmt.Fprintf(w, "%s", string(body))
		fmt.Fprintf(os.Stdout, "%s", string(body))
	} else {

		fmt.Fprintf(os.Stderr , "Error while getting a response: %s\n", response.Status )
		fmt.Fprintf(w, "error while getting a response %s", response.Status, http.StatusBadRequest)
	}

	delErr := clientset.CoreV1().Pods(podNs).Delete(context.TODO(), pod_name, metav1.DeleteOptions{})

	if delErr != nil {
  		log.Fatal(err)
	}
   
   return
}

func main() {

	port , found := os.LookupEnv("PORT_NUMBER")

	if !found {
		port = "8080"
	}

    http.HandleFunc("/", intro)
	http.HandleFunc("/listnodes", listnodes)
	http.HandleFunc("/checkport", checkport)

	log.Printf("Starting Listener on Port : %s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}