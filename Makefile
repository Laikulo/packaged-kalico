all: kalico/.version kalico/pyproject.toml

.PHONY: all pyenv pybuild pytree

pyenv: .venv/.deps-installed

pybuild: pyenv pytree
	./.venv/bin/pyproject-build kalico

pytree: kalico/pyproject.toml kalico/.version

.venv/.deps-installed: .venv/pyvenv.cfg bin/gen-pyproject
	.venv/bin/pip install --requirements-from-script bin/gen-pyproject build
	touch .venv/.deps-installed

kalico/pyproject.toml: kalico.upstream/pyproject.toml kalico/.version bin/gen-pyproject .venv/.deps-installed
	.venv/bin/python3 bin/gen-pyproject --verfile kalico/.version $< $@
	

.venv/pyvenv.cfg:
	python3 -m venv .venv --upgrade-deps --prompt pkgtools

kalico/.version: .git/modules/kalico/HEAD
	test -d kalico || mkdir kalico
	cp -r \
		kalico.upstream/COPYING \
		kalico.upstream/README.md \
		kalico.upstream/klippy \
		kalico
	
	GIT_DIR=kalico.upstream/.git \
	GIT_WORK_TREE=kalico.upstream \
	git describe --always --tags --long > $@
	
clean:
	rm -rf kalico
