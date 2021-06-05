.PHONY: get put getpts log doc

put:
	rsync -vrt --delete --exclude=.git . /Volumes/Elder\ Scrolls\ Online/live/AddOns/ZZCompanion
