# Purchase Data Analytics

Purchase Data Analytics is a proof of concept application for demonstrating the reverse use of customer data. The application allow informants to import purchase data made available to customers by S Group, and grocery shopping receipts. The receipts complete otherwise sparse purchase data with nutritional details. Lastly, the data is visualized for the informant to evaluate its usefulness and meaningfulness.

<a target="_blank" href="https://gitlab.com/petterip/purchase-data/raw/master/dev-resources/screenshot_items.jpg">
<img src="https://gitlab.com/petterip/purchase-data/raw/master/dev-resources/screenshot_items.jpg" width=400></a>
<a target="_blank" href="https://gitlab.com/petterip/purchase-data/raw/master/dev-resources/screenshot_purchases.jpg">
<img src="https://gitlab.com/petterip/purchase-data/raw/master/dev-resources/screenshot_purchases.jpg" width=400></a><br/>
<a target="_blank" href="https://gitlab.com/petterip/purchase-data/raw/master/dev-resources/screenshot_proto1.jpg">
<img src="https://gitlab.com/petterip/purchase-data/raw/master/dev-resources/screenshot_proto1.jpg" width=200></a>
<a target="_blank" href="https://gitlab.com/petterip/purchase-data/raw/master/dev-resources/screenshot_proto2a.jpg">
<img src="https://gitlab.com/petterip/purchase-data/raw/master/dev-resources/screenshot_proto2a.jpg" width=200></a>
<a target="_blank" href="https://gitlab.com/petterip/purchase-data/raw/master/dev-resources/screenshot_proto2b.jpg">
<img src="https://gitlab.com/petterip/purchase-data/raw/master/dev-resources/screenshot_proto2b.jpg" width=200></a>
<a target="_blank" href="https://gitlab.com/petterip/purchase-data/raw/master/dev-resources/screenshot_proto3.jpg">
<img src="https://gitlab.com/petterip/purchase-data/raw/master/dev-resources/screenshot_proto3.jpg" width=200></a>

## Prerequisites

You will need [Leiningen][1] 2.0 or above installed.

[1]: https://github.com/technomancy/leiningen

## Demo

Application demo with some sample data is available at http://ostosdata.oulu.fi:8080/items?secret=aWQ4. Feel free to play with it as much as you like.

## Running

First, create the database by runnning:

    lein run migrate 

To start a web server for the application, run:

    lein run
    
or to run the application in a specific port:

    lein run 8000

## API calls

The application serves the following API calls:

* GET /api/purchases/ <br/>get all the purchases of every user.
* GET /api/purchases/<id> <br/>get the purchases belonging to a particular user.
* GET /api/purchases/<id>/totals <br/>get the purchase totals of a particular user.
* GET /api/purchases/<id>/date/<date> <br/>get the purchases of specific date (date in format YYYY-MM-DD).
* GET /api/purchases/<id>/top5 <br/>get the top purchases of a single user (sorted by costs).
* GET /api/purchases/<id>/top5-count <br/>get the top purchases of a single user (sorted by amounts).

* GET /api/nutrition/<id> <br/>get the nutrients from a particular user's purchases.
* GET /api/nutrition/<id>/month <br/>get the nutrients from a particular user's purchases, grouped by months.
* GET /api/nutrition/<id>/week <br/>get the nutrients from a particular user's purchases, grouped by weeks.
* GET /api/nutrition/<id>/date/<month>/<nutrient> <br/>get the top nutrients from a particular user's purchases, for a given month, and sorted by <nutrient>.
* GET /api/nutrition/<id>/category <br/>get the nutrients from a particular user's purchases including all the purchases.
* GET /api/nutrition/<id>/total <br/>get a summary from a particular user's purchases including all the purchases.

<br/>
Note: the repository does not contain file 'all_prods.json' which is necessary for recognizing receipts. Please [contact the author](mailto:petteri.ponsimaa@oulu.fi) for instructions how to get it.

## License

This project is licensed under [MIT License](http://opensource.org/licenses/MIT).