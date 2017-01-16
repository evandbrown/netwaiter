# Deploy reproduction
1. Edit the Makefile to use a GCS bucket that you own
1. Do `make upload` to build and upload the server application
1. Use Terraform to deploy the repro:

  ```
  terraform apply -var project=REPLACE -var bin_url=https://storage.googleapis.com/REPLACE/netwaiter
  ```

1. Get the `try_it` output var, and paste it to run the command:

  ```
  $ terraform output try_it
  curl "http://35.186.197.120:8080/sleep?duration=3s&request_id=$RANDOM"
  $ curl "http://35.186.197.120:8080/sleep?duration=3s&request_id=$RANDOM"
  <html><head>
  <meta http-equiv="content-type" content="text/html;charset=utf-8">
  <title>502 Server Error</title>
  </head>
  <body text=#000000 bgcolor=#ffffff>
  <h1>Error: Server Error</h1>
  <h2>The server encountered a temporary error and could not complete your request.<p>Please try again in 30 seconds.</h2>
  <h2></h2>
  </body></html>
  ```

If you're unsure if the application is deployed, get the `health` output and try curling it. It should return an HTTP 200 immediately:

  ```
  $ terraform output health
  http://35.186.197.120:8080/healthz
  $ curl http://35.186.197.120:8080/healthz
  ```

