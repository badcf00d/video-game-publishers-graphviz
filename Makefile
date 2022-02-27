SHELL = bash
GRAPH := publishers.png
DOT_FILE := $(wildcard *.dot)
HIRES_PNG := $(shell find images/hires -type f -name '*.png')
PNG_MIN := $(subst /hires,,$(HIRES_PNG))
PNG_OPT := $(HIRES_PNG:%.png=%.png.opt)
DATE_STRING := $(shell date -u +"%F-%T-UTC")
GIT_STRING := $(shell git describe --always --dirty)
GENERATE_STRING := $(shell printf "%s (%s)" $(DATE_STRING) $(GIT_STRING))

.PHONY: graph hires images clean release checks
graph: $(GRAPH)
hires: $(PNG_OPT)
images: $(PNG_MIN)


$(GRAPH): $(DOT_FILE) $(PNG_MIN)
	$(info Making graph $(GENERATE_STRING): $(notdir $<) --> $(notdir $@))
	@sed 's/{GENERATE_TEXT}/$(GENERATE_STRING)/' $< | twopi -Tpng -o $@

release: $(GRAPH)
	@optipng -zc9 -zm8 -zs0 -f0 -clobber -strip all $<

%.png.opt: %.png
	$(info Optipng: $(notdir $<))
	@mogrify +profile "*" -fuzz 1% -trim +repage -flatten -background none -resize 1024x1024\> $<
	@optipng -o4 -clobber -silent -strip all $<

images/%.png: images/hires/%.png
	$(info Resizing: $(notdir $<))
	@convert $< -resize 6000@ $@

clean:
	@rm -f $(PNG_MIN) $(GRAPH)

checks: $(DOT_FILE)
	@diff -s -a -y --color=always --suppress-common-lines \
		<(find ./images/hires/ -type f -printf "%f\n" -iname "*.png" | sort) --label "PNG files" \
		<(grep -o -P "[\w\d]*.png" $< | sort) --label "Files mentioned in graph"