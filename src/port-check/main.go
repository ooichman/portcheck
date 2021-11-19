package main

import (
	"fmt"
	"os"
	"encoding/json"
	"net/http"
	"net"
	"time"
	"io/ioutil"
	"log"
)

type Postinput struct {
	Port string `json:"port"`
	Target string `json:"target"`
	Protocol string `json:"protocol"`
}

type Postoutput struct {
	Status string `json:"status"`
	Message string `json:"message"`
}

func WebForm(w http.ResponseWriter, r *http.Request ) {

	fmt.Fprintf(w, "Web Form under Constraction\n")
	fmt.Fprintf(os.Stdout,"Web Form under Constraction\n")
	return
}

func portcheck(w http.ResponseWriter, r *http.Request) {
	
	if r.URL.Path != "/portcheck" {
		fmt.Fprintf(os.Stderr,"Not A valid URL PATH\n")
		http.Error(w, "Not A valid URL PATH", http.StatusBadRequest)
		return
	}

	if r.Method != "POST" {
		fmt.Fprintf(os.Stderr, "You arenot using POST Method to query\n")
		http.Error(w, "You arenot using POST Method to query", http.StatusBadRequest)
		return
	}

	var Body []byte
	if r.Body != nil {
		if data , err := ioutil.ReadAll(r.Body); err == nil {
			Body = data
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

    port := input.Port
    target := input.Target
    protocol := input.Protocol

    timeout := time.Second
    conn , err := net.DialTimeout(protocol, net.JoinHostPort(target, port), timeout)

	if err != nil {
    	fmt.Fprintf(os.Stderr, "Unable to Open Port %s to host %s on protocol : %s\n",port , target, protocol)
    }

	contentType := r.Header.Get("Content-type")
	fmt.Fprintf(os.Stdout, "%s\n", contentType)

    if contentType == "application/json" {

    	postoutput := Postoutput{
    		Status: "Failure",
    		Message: "unable to reach request host on the request port",
    	}

    	resp , err_resp := json.Marshal(postoutput)

	    if conn != nil {
    		postoutput.Status = "Success"
    		postoutput.Message = "the port is opened on the remote host"

    		resp , err_resp = json.Marshal(postoutput)

	    	fmt.Fprintf(os.Stdout, "Port %s/%s is open on remote host %s\n",port , protocol , target)
   		 }

  		if err_resp != nil {
	    	fmt.Fprintf(os.Stderr, "Unable to Marshal the Request\n")
 		   	http.Error(w, "Unable to Marshal the Request", http.StatusBadRequest)
	    	return
   		}

   		if _ , werr := w.Write(resp); werr != nil {
   			fmt.Fprintf(os.Stderr, "Unable to Write the Response\n")
   			http.Error(w, "Unable to Write Response", http.StatusBadRequest)    	
   		}
    	return
    }
}

func main() {

	port, found := os.LookupEnv("PORT_NUMBER")	

	if !found {
		port = "8080"
	}

	http.HandleFunc("/", WebForm)
	http.HandleFunc("/portcheck", portcheck)

	log.Printf("Staring to Listen on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}