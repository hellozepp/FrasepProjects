VA Realtime reporting with randomly generated trades events

This simple project has been used to showcase ESP Studio, Model Manager integration and VA realtime dashboarding on SAS Viya 3.5.
Warning : a SMP server with all VA/VS/VDMML/ESP has been installed, and ssl had to be activated to avoid problems with ESP Studio
direct websocket connection to ESP Server for test interface.
More over to integrate MM with ESP, the following symbolic link had to be created (with 775 rights for sas group - the demo user must belong to this group-) : 
/models/astores/viya pointing on existing directory /opt/sas/viya/config/data/modelsvr/astore
This is mandatory to let ESP Micro analytics services and MM see the astores produced by the model registering actions.
For exemple these commands on linux :
sudo mkdir -p /models/astores
sudo ln -s /opt/sas/viya/config/data/modelsvr/astore /models/astores/viya
sudo chmod -R 775 /models/astores
sudo chown -R sas:sas /models

2021-10-07 : new report, new training (model isolation forest), and new esp model pointing on trade.csv file instead of trade generator project

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
- reexcute training code to produce new model and project in MM automaticazlly. Then go to project Trades_ML001 in MM, and set the model as 
  champion by adding SVDD_SCORE as project output when a dialog requests it
- go to esp studio and edit the trades project for scoring windows by reimporting the right model to MAS from MM
- publish the trades generator by executing publish_trades_generator.sh
- in esp studio launch the trades project in test mode and verify th event coming in
- launch the trade generator by executing launch_trade_generator.sh (by default : 1,000,000 events, with 100 per seconds)
- start the SAS script to substribe to the stream and populate on the fly the two CAS tables used in reporting : streamTrades and streamTotalcost in public



