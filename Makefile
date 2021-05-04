.PHONY: docker clean clean-venv check ci-test pre-commit quality run style tag-version test venv upload upload-test

PROJECT=fcos
PY_VER=python3.9
PY_VER_SHORT=py$(shell echo $(PY_VER) | sed 's/[^0-9]*//g')
QUALITY_DIRS=$(PROJECT) tests setup.py
CLEAN_DIRS=$(PROJECT) tests
VENV=$(shell pwd)/venv
PYTHON=$(VENV)/bin/python

LINE_LEN=120
DOC_LEN=120

VERSION := $(shell cat version.txt)

CONFIG_FILE := Makefile.config
ifneq ($(wildcard $(CONFIG_FILE)),)
include $(CONFIG_FILE)
endif


check: 
	$(MAKE) style
	$(MAKE) quality
	$(MAKE) test

clean: 
	find $(CLEAN_DIRS) -path '*/__pycache__/*' -delete
	find $(CLEAN_DIRS) -type d -name '__pycache__' -empty -delete
	find $(CLEAN_DIRS) -name '*@neomake*' -type f -delete
	find $(CLEAN_DIRS) -name '*.pyc' -type f -delete
	find $(CLEAN_DIRS) -name '*,cover' -type f -delete
	rm -rf dist

clean-venv:
	rm -rf $(VENV)

demo: $(CONFIG_FILE)
	$(PYTHON) -m $(PROJECT) trainer.params.default_root_dir=$(OUTPUT_PATH)

docker-build: 
	docker build \
		--target release \
		-t $(PROJECT):latest \
		--file ./docker/Dockerfile \
		./

docker-run: $(CONFIG_FILE)
	mkdir -p ./outputs ./data ./conf
	docker run --rm -it --name $(PROJECT) \
		--gpus all \
		--shm-size 8G \
		-v $(DATA_PATH):/app/data \
		-v $(CONF_PATH):/app/conf \
		-v $(OUTPUT_PATH):/app/outputs \
		$(PROJECT):latest \
		-c "python examples/basic"

init:
	git submodule update --init --recursive
	$(MAKE) venv

package: venv
	rm -rf dist
	$(PYTHON) -m pip install --upgrade setuptools wheel
	export COMBUSTION_BUILD_VERSION=$(VERSION) && $(PYTHON) setup.py sdist bdist_wheel

pre-commit: 
	pre-commit install

quality: $(VENV)/bin/activate-quality
	$(MAKE) clean
	$(PYTHON) -m black --check --line-length $(LINE_LEN) --target-version $(PY_VER_SHORT) $(QUALITY_DIRS)
	$(PYTHON) -m flake8 --max-doc-length $(DOC_LEN) --max-line-length $(LINE_LEN) $(QUALITY_DIRS) 

run: $(CONFIG_FILE)
	$(PYTHON) -m $(PROJECT)

style: $(VENV)/bin/activate-quality
	$(PYTHON) -m autoflake -r -i --remove-all-unused-imports --remove-unused-variables $(QUALITY_DIRS)
	$(PYTHON) -m isort $(QUALITY_DIRS)
	$(PYTHON) -m autopep8 -a -r -i --max-line-length=$(LINE_LEN) $(QUALITY_DIRS)
	$(PYTHON) -m black --line-length $(LINE_LEN) --target-version $(PY_VER_SHORT) $(QUALITY_DIRS)

tag-version: version.txt
	git tag -a "$(VERSION)"

test: $(VENV)/bin/activate-test
	$(PYTHON) -m pytest \
		-rs \
		--cov=./src \
		--cov-report=xml \
		-s -v \
		./tests/

test-%: $(VENV)/bin/activate-test
	$(PYTHON) -m pytest -rs -k $* -s -v ./tests/ 

test-pdb-%: $(VENV)/bin/activate-test
	$(PYTHON) -m pytest -rs --pdb -k $* -s -v ./tests/ 

upload: package
	$(PYTHON) -m pip install --upgrade twine
	$(PYTHON) -m twine upload --repository pypi dist/*

upload-test: package
	$(PYTHON) -m pip install --upgrade twine
	$(PYTHON) -m twine upload --repository testpypi dist/*

venv: $(VENV)/bin/activate

$(VENV)/bin/activate: setup.py requirements.txt 
	test -d $(VENV) || $(PY_VER) -m venv $(VENV)
	$(PYTHON) -m pip install -U pip 
	$(PYTHON) -m pip install -r requirements.txt
	$(PYTHON) -m pip install -e .
	touch $(VENV)/bin/activate

$(VENV)/bin/activate-%: requirements.%.txt
	test -d $(VENV) || $(PY_VER) -m venv $(VENV)
	$(PYTHON) -m pip install -U pip 
	$(PYTHON) -m pip install -r $<
	touch $(VENV)/bin/activate-$*