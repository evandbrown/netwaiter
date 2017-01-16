package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"
)

func handler(w http.ResponseWriter, r *http.Request) {
	var duration, reqId string

	if duration = r.URL.Query().Get("duration"); duration == "" {
		w.WriteHeader(400)
		w.Write([]byte("A duration parameter (e.g., 5s) is required"))
		return
	}
	if reqId = r.URL.Query().Get("request_id"); reqId == "" {
		w.WriteHeader(400)
		w.Write([]byte("A request_id parameter is required"))
		return
	}

	if d, err := time.ParseDuration(duration); err == nil {
		h, _ := json.Marshal(r.Header)
		log.Printf("netwaiter: request %s from %s durationing for %v. Headers: %+v", reqId, r.RemoteAddr, duration, string(h))
		time.Sleep(d)
		w.WriteHeader(200)
		w.Write([]byte(fmt.Sprintf("netwaiter: request %q completed after %v\n", reqId, duration)))
	}
}

func main() {
	http.HandleFunc("/sleep", handler)
	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) { w.WriteHeader(200) })
	http.ListenAndServe(":8080", nil)
}
