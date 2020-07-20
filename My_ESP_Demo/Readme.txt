VA Realtime reporting with randomly generated trades events

This simple project has been used to showcase ESP Studio, Model Manager integration and VA realtime dashboarding on SAS Viya 3.5.
Warning : a SMP server with all VA/VS/VDMML/ESP has been installed, and ssl had to be activated to avoid problems with ESP Studio
direct websocket connection to ESP Server for test interface.

Components :
- trades ESP project trades.xml (to be imported in ESP Studio)
- trades event generator : trades_generator.xml
- VA trades realtime dashboard report json export
- SAS Script to launch stream CAS subscriptions to 2 realtime windows at the same time (parallel sessions).
- Shell scripts to manage esp servers and events start and stop () 
- traders data traders.csv
- a sas script to train the SVDD model and publish the model to MM used in the demo

How to install :
****************

- copy all the files on the server in a single directory like for example : /opt/demo/trades_esp
- import the report in Viya through EV
- import the sas program used or open it in sas studio
- 

How to run the demo :

- log in with sas installer user
- launch esp studio and import the project
- start the esp server with start_esp_server.sh
- import the model
- publish the trades generator by executing publish_trades_generator.sh
- in esp studio launch the trades project in test mode and verify th event coming in
- launch the trade generator by executing launch_trade_generator.sh (by default : 1,000,000 events, with 100 per seconds)
- start the SAS script to substribe to the stream and populate on the fly the two CAS tables used in reporting : streamTrades and streamTotalcost in public



