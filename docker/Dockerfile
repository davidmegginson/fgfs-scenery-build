FROM flightgear/terragear:ws20
USER root
RUN groupadd -g 1001 david
RUN useradd -u 1001 -g 1001 david
USER david
CMD /bin/bash