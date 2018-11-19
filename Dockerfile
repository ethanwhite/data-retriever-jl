FROM julia:0.7.0-stretch

MAINTAINER weecology "https://github.com/weecology/Retriever.jl"

# Install Python3 and Retriever
RUN apt-get update
RUN apt-get install -y --force-yes build-essential wget git
# postgresql-client for local tests and command line connections (psql)
RUN apt-get install -y --force-yes postgresql-client locales locales-all

# Set encoding
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Remove python2 and install python3
RUN apt-get remove -y python && apt-get install -y python3  python3-pip curl

RUN rm -f /usr/bin/python && ln -s /usr/bin/python3 /usr/bin/python
RUN rm -f /usr/bin/pip && ln -s /usr/bin/pip3 /usr/bin/pip

RUN echo "export PATH="/usr/bin/python:$PATH"" >> ~/.profile
RUN echo "export PYTHONPATH="/usr/bin/python:$PYTHONPATH"" >> ~/.profile

RUN echo "export PGPASSFILE="~/.pgpass"" >> ~/.profile
RUN chmod 0644 ~/.profile
 
# Install retriever master
RUN pip install git+https://git@github.com/weecology/retriever.git  && retriever ls
RUN pip install psycopg2 pymysql

COPY . /Retriever.jl

# Use entrypoint to run more configurations.
# set permissions. 
# entrypoint.sh will set out config files 
RUN chmod 0755 /Retriever.jl/cli_tools/entrypoint.sh
ENTRYPOINT ["/Retriever.jl/cli_tools/entrypoint.sh"]

WORKDIR /Retriever.jl

# Check installations
RUN julia -e 'using InteractiveUtils; versioninfo()'
RUN julia -e 'using Pkg;Pkg.update()'
RUN julia -e 'using Pkg; Pkg.add("PyCall")'
RUN echo $PYTHON
RUN echo $JULIA_LOAD_PATH

# Add permissions to config files
RUN export PGPASSFILE="~/.pgpass"
RUN chmod 600 cli_tools/.pgpass
RUN chmod 600 cli_tools/.my.cnf

# Let image just check the version.
# Can overwrite this in to run julia test/runtests.jl,
# (Check travis file).
# CMD ["bash", "-c", "julia test/runtests.jl"]

CMD ["bash", "-c", "julia versioninfo()"]

