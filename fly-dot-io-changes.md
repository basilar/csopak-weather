Changelog
=========

2025-10-21
----------
Starting January 1st, 2026, we'll begin charging for volume snapshots storage. The first charges will be on invoices issued at the start of February 2026. The price will be $0.08/GB per month, with the first 10 GB free each month.
Your Fly.io organizations with volume snapshots are:
    <REDACTED> with 32.7 MB of volume snapshots stored

Usage is calculated based on the total stored size of the snapshots, not the provisioned volume size. You're only charged for the actual data stored - if you've written 1 GB to a 10 GB volume, you'll be charged for around 1 GB of snapshot storage.
Additionally, snapshots are stored incrementally, meaning you only pay for data that has changed since the previous snapshot.

➜ fly volumes list -a csopak-weather-db 
ID                  	STATE  	NAME   	SIZE	REGION	ZONE	ENCRYPTED	ATTACHED VM   	CREATED AT 
<REDACTED>	            created	pg_data	1GB 	fra   	910c	false    	<REDACTED>   	1 year ago	

➜ fly volumes update <REDACTED> --snapshot-retention 0 -a csopak-weather-db 
                  ID: <REDACTED>
                Name: pg_data
                 App: csopak-weather-db
              Region: fra
                Zone: 910c
             Size GB: 1
           Encrypted: false
          Created at: 02 Jul 24 23:01 UTC
  Snapshot retention: 5
 Scheduled snapshots: false

➜ fly volumes update <REDACTED> --scheduled-snapshots=false -a csopak-weather-db
                  ID: <REDACTED>
                Name: pg_data
                 App: csopak-weather-db
              Region: fra
                Zone: 910c
             Size GB: 1
           Encrypted: false
          Created at: 02 Jul 24 23:01 UTC
  Snapshot retention: 5
 Scheduled snapshots: false
