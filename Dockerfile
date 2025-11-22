FROM python:3.12-alpine
RUN python3 -m pip install pgn_to_sqlite
ENTRYPOINT ["pgn-to-sqlite"]