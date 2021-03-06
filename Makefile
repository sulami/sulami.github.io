.PHONY: help deploy build live clean compile convert

help:
	@echo "Commands:"
	@grep '^[a-z]' Makefile | awk '{print $$1}' | sed 's/^/- /;s/:$$//'

deploy:
	# Temporarily store uncommited changes
	git stash --include-untracked

	# Verify correct branch
	git checkout develop

	# Update sources
	git push origin develop:develop

	# Build new files
	make build

	# Get previous files
	git fetch --all
	rm -rf tufte
	git checkout -B master --track origin/master

	# Overwrite existing files with new files
	rsync -a 								   \
		--filter='P _site/'      \
		--filter='P _cache/'     \
		--filter='P .git/'       \
		--filter='P .gitignore'  \
		--filter='P .stack-work' \
		--delete-excluded        \
		_site/ .

	# Commit
	git add -A
	git commit -m "Publish."

	# Push
	git push origin master:master

	# Restoration
	git checkout develop
	git branch -D master
	git submodule update -f
	git stash pop || true

build: compile clean
	racket export-metadata.rkt
	stack exec blog build

live: compile clean
	racket export-metadata.rkt
	stack exec blog watch

clean:
	stack exec blog clean

compile:
	stack build
