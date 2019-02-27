.PHONY: help clean clean-all dev build test code deploy release deploy-prod

pkg := gensim
codedir := $(pkg)
testdir := test

syspython := python3

python := venv/bin/python
pip := venv/bin/pip-s3
aws := venv/bin/aws

help:
	@echo
	@printf "help\t Display this help message\n"
	@echo
	@printf "clean\t Clean build artifacts but NOT downloaded assets\n"
	@printf "clean-all\t Clean everything\n"
	@echo
	@printf "dev\t Setup the local dev environment\n"
	@printf "build\t Build into local environment (for use in REPL, etc.)\n"
	@printf "test\t Run unit tests\n"
	@printf "code\t Build code, and run all checks (tests, pep8, manifest check, etc.)\n"
	@echo
	@printf "deploy\t Upload to private PyPI under the branch.  Normally called by CircleCI\n"
	@printf "release\t Release a new prod version: add a tag and Circle builds and uploads.\n"
	@printf "       \t Add a release message: \"make release msg='My release message'\"\n"
	@printf "deploy-prod\t EMERGENCY USE ONLY.  Upload to private PyPI under the version number.\n"
	@printf "           \t Normally called by CircleCI\n"
	@echo

clean:
	rm -rf build
	rm -rf dist
	find $ . -name '*.py[co]' -delete
	find $ . -name '__pycache__' -exec rm -Rf {} +
	rm -rf *.egg-info
	rm -rf *.eggs
	rm -rf *.whl
	rm -rf $(testdir)/out_test/
	rm -rf htmlcov/
	rm -rf .cache/
	rm -f .coverage
	rm -rf venv
	rm -f .venv
	rm -f .dev
	rm -f .build
	rm -f .test
	rm -f .code
	rm -rf $(pkg)-*

clean-all: clean

venv:
	$(syspython) -m venv venv

.venv: venv
	venv/bin/pip install --upgrade pip wheel setuptools
	venv/bin/pip install "awscli"
	$(aws) s3 cp s3://textio-pypi-us-west-2/pypi/0/dev/pips3/pips3-master.tar.gz .
	venv/bin/pip install pips3-master.tar.gz
	rm -f pips3-master.tar.gz
	touch .venv

.dev: .venv
	$(pip) install -r requirements_dev.txt
	touch .dev

.build: .dev
	$(pip) install -e .
	touch .build

.test: .dev .build
	pytest gensim/test/test_ldamodel.py --disable-warnings
	touch .test

.code: .dev .build .test
	$(python) setup.py check
	touch .code

dev: .dev

build: .build

test: .test

code: .code

deploy: .dev .code
	. venv/bin/activate && deploy.sh ./setup.py dev

msg ?=
release: .dev .code
	. venv/bin/activate && release.sh ./setup.py "$(msg)"

deploy-prod: .dev .code
	. venv/bin/activate && deploy.sh ./setup.py prod
