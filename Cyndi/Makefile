.PHONY: app notarize dmg release clean

VERSION ?=

app:
	./scripts/package.sh $(VERSION)

notarize:
	./scripts/notarize.sh

dmg release:
	./scripts/release.sh $(VERSION)

clean:
	rm -rf dist
	swift package clean
