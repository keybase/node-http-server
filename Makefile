

run:
	node bin/app.js

test:
	(cd test && iced run.iced)

.PHONY: run, test
	
