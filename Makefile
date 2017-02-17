.PHONY: all clean watch

NODE := $(shell which node)
LESSC := node_modules/.bin/lessc
HANDLEBARS := node_modules/.bin/handlebars
POSTCSS := scripts/postcss.js


lessfiles := $(shell find css/ -name "*.less")
cssfiles := $(lessfiles:%.less=%.css)
handlebars := $(shell find views/ -name "*.hbs")
allcss = $(shell find css/ -name "*.css" \
			| grep -v 'reset.css')
alljs = $(shell echo "main.js" \
			&& find {config,controllers,handlers,locales,lib,models,turtl} -name "*.js" \
			| grep -v '(ignore|\.thread\.)')
testsjs = $(shell find tests/{data,tests} -name "*.js")

all: $(cssfiles) lib/app/templates.js lib/app/svg-icons.js .build/postcss index.html

%.css: %.less
	@echo "- LESS:" $< "->" $@
	@$(LESSC) --include-path=css/ $< > $@

lib/app/templates.js: $(handlebars)
	@echo "- Handlebars: " $?
	@$(HANDLEBARS) -r views -e "hbs" -n "TurtlTemplates" -f $@ $^
	@echo 'var TurtlTemplates = {};' > .build/templates.js
	@cat $@ >> .build/templates.js
	@mv .build/templates.js $@

lib/app/svg-icons.js:
	@./scripts/index-icons $@

.build/postcss: $(allcss) $(cssfiles)
	@echo "- postcss:" $?
	@$(NODE) $(POSTCSS) --use autoprefixer --replace $?
	@touch $@

index.html: $(allcss) $(alljs) $(cssfiles) lib/app/templates.js views/layouts/default.html .build/postcss scripts/include.sh scripts/gen-index
	@echo "- index.html: " $?
	@./scripts/gen-index

tests/index.html: $(testsjs) index.html tests/scripts/gen-index
	@echo "- tests/index.html: " $?
	@./tests/scripts/gen-index

clean:
	rm -f $(allcss)
	rm -f lib/app/templates.js
	rm -f lib/app/svg-icons.js
	rm -f .build/*
	rm -f index.html

watch:
	@./scripts/watch

min.index.html: $(allcss) $(alljs) $(cssfiles) lib/app/templates.js views/layouts/default.html .build/postcss scripts/include.sh scripts/gen-minified-index
	@echo "- index.html: " $?
	@./scripts/gen-minified-index


minify: $(cssfiles) lib/app/templates.js lib/app/svg-icons.js .build/postcss min.index.html
