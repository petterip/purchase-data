# Purchase Data Analytics

Purchase Data Analytics is a proof of concept application for demonstrating the reverse use of customer data. The application allow informants to import purchase data made available to customers by S Group, and grocery shopping receipts. The receipts complete otherwise sparse purchase data with nutritional details. Lastly, the data is visualized for the informant to evaluate its usefulness and meaningfulness.

<a target="_blank" href="https://gitlab.com/petterip/purchase-data/raw/master/dev-resources/screenshot_items.jpg">
<img src="https://gitlab.com/petterip/purchase-data/raw/master/dev-resources/screenshot_items.jpg" width=400></a>
<a target="_blank" href="https://gitlab.com/petterip/purchase-data/raw/master/dev-resources/screenshot_purchases.jpg">
<img src="https://gitlab.com/petterip/purchase-data/raw/master/dev-resources/screenshot_purchases.jpg" width=400></a>

## Prerequisites

You will need [Leiningen][1] 2.0 or above installed.

[1]: https://github.com/technomancy/leiningen

## Running

First, create the database by runnning:

    lein run migrate 

To start a web server for the application, run:

    lein run
    
or to run the application in a specific port:

    lein run 8000

## API calls

The application serves the following API calls:

* GET /purchases/ <br/>get all the purchases stored in the database in JSON
* GET /purchases/id <br/>get purchases of a specific user ID

<br/>
Note: the repository does not contain file 'all_prods.json' which is necessary to for recognizing receipts. Please [contact the author](mailto:petteri.ponsimaa@oulu.fi) for instructions how to get it.

## License

This project is licensed under [MIT License](http://opensource.org/licenses/MIT).