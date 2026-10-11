.PHONY: all build run help

all: build run ## Build the Docker image and run the default example

build: ## Build the realpaver:latest Docker image
	docker build -t realpaver:latest .

run: ## Run examples/2r-robot.rp in the Docker image
	docker run -t --rm \
		-u $(shell id -u):$(shell id -g) \
		-v $(shell pwd):/workspace \
		-w /workspace \
		realpaver:latest \
		examples/2r-robot.rp

help: ## Show help for each target
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)