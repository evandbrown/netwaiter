upload:
	go build
	gsutil cp -a public-read netwaiter gs://evandbrown17/
	rm netwaiter
