all: pybuild

RELEASE=dev3

.PHONY: all pyenv pybuild pytree check

pyenv: .venv/.deps-installed

pybuild: pyenv pytree
	./.venv/bin/pyproject-build kalico --outdir dist/

pytree: kalico/pyproject.toml kalico/.version kalico/README.md

.venv/.deps-installed: .venv/pyvenv.cfg bin/gen-pyproject
	.venv/bin/pip install --requirements-from-script bin/gen-pyproject build
	touch .venv/.deps-installed

kalico/pyproject.toml: kalico.upstream/pyproject.toml kalico/.version bin/gen-pyproject .venv/.deps-installed
	.venv/bin/python3 bin/gen-pyproject --verfile kalico/.version --pre "$(RELEASE)" $< $@

kalico/README.md: fork-banner.md.inc kalico.upstream/README.md
	cat $^ > $@
	

.venv/pyvenv.cfg:
	python3 -m venv .venv --upgrade-deps --prompt pkgtools

HELPER_SCRIPTS = console.py

kalico/.version: .git/modules/kalico/HEAD
	test -d kalico || mkdir kalico
	cp -r \
		kalico.upstream/COPYING \
		kalico.upstream/klippy \
		kalico
	test -d kalico/kalico/scripts || mkdir -p kalico/kalico/scripts
	cp $(foreach x,$(HELPER_SCRIPTS),kalico.upstream/scripts/$x) kalico/kalico/scripts
	touch kalico/kalico/scripts/__init__.py kalico/kalico/__init__.py
	GIT_DIR=kalico.upstream/.git \
	GIT_WORK_TREE=kalico.upstream \
	git describe --always --tags --long > $@

.venv.test/pyvenv.cfg:
	python3 -m venv .venv.test --upgrade-deps --prompt kalico

.venv.test/.installed: .venv.test/pyvenv.cfg
	.venv.test/bin/pip install dist/kalico*.whl
	touch $@

check: .venv.test/.installed
	.venv.test/bin/kalico --import-test

clean:
	rm -rf kalico dist .venv.test

distclean: clean
	rm -rf .venv
