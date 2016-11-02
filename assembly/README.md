This file contains the machinery for obtaining the data used to build the dataset.
The primary "hinge" is the `fec_results_generator` Ruby gem, found [here](https://github.com/openelections/fec_results_generator).
You do need to install it by cloning the repository then running `gem install 'fec_results_generator` in it.
Once that gem is installed you can fetch the base dataset with

```
ruby get_election_results.rb
```
The results are placed in a directory called `api`, with a directory tree for each year.

The other main utility script is `flat_json_to_csv.sh`, which is a shell script that converts the very strange JSON-inside-JSON format of the result files to flat CSVs. 
The JSON structures themselves are flat, so CSV is a much more convenient format to work with when constructing the full dataset.

You'll find documentation on the individual files and their columns in `notes.md`.