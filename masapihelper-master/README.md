Big thanks to Mathias Bouten of the Global CI Practice for creating this app!

See his [blog](http://sww.sas.com/blogs/wp/gpci/viya-api-helper/)!

This app has already been deployed to the [Global CI GOLD RACE image](http://race.exnet.sas.com/ImageDefRpt?imgDefId=3860&imageId=123583&imageType=C),
but you can download it here to run in any python 3 environment.

Here are the set up instructions:
* Install the [Ananconda 3 python environment](https://www.anaconda.com/download/)
* Install the one package that doesn’t come with anaconda: “pip install jwt”
* Download this repository and 'cd' into this folder (masapihelper)
* Run the application: "python routes.py"
* Visit "http://IP_OF_MACHINE_RUNNING_APP:8077/"
* Enter your viya server in the dialog and click get token
* Visit MAS page to run models/decisions published to MAS
