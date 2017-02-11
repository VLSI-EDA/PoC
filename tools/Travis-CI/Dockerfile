FROM ghdl/ext:vunit

WORKDIR /work

COPY ./* /tools/

RUN ln -s $(which python3) /usr/bin/python3 \
 && pip3 install -r /tools/requirements.txt \
 && /tools/grc.setup.sh \
 && ghdl -v
