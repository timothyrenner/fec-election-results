# Dataset Assembly

This directory contains all of the scripts and auxiliary files needed to reconstruct the dataset.

## Quick Start

First we need to seed the data with the `fec_results_generator` API.

```
ruby get_election_results.rb
```

Next convert the necessary files to CSVs.

```
./convert_results.sh
```

Now that the CSVs are in place, use the R script to build the data.

```
Rscript build.R
```

This puts the file `fec_tidy.csv` one directory above this one in the repository root.

## More Details 

This file contains the machinery for obtaining the data used to build the dataset.
The primary "hinge" is the `fec_results_generator` Ruby gem, found [here](https://github.com/openelections/fec_results_generator).
You do need to install it by cloning the repository then running `gem install 'fec_results_generator` in it.
Once that gem is installed you can fetch the base dataset with

```
ruby get_election_results.rb
```
The results are placed in a directory called `api`, with a directory tree for each year.
You'll find documentation on the individual files and their columns in `notes.md`.

The other main utility script is `flat_json_to_csv.sh`, which is a shell script that converts the very strange JSON-inside-JSON format of the result files to flat CSVs. 
The JSON structures themselves are flat, so CSV is a much more convenient format to work with when constructing the full dataset.
There's a wrapper, `convert_results.sh`, that converts all of the files needed to build the dataset into CSVs.

The main script to build the dataset is `build.R`.
It requires the `tidyverse` and `stringr` libraries, and is well commented so the procedure for cleaning up the data is not only reproducible but also understandable.

There are three auxiliary CSV files used in the build script:

1. `party_cleanup.csv` takes the party labels as they appear in the datasets and maps them onto a standardized set of symbols. This is necessary because of ballot modifiers like W(D) for Democrat write-in as well as different representations of the same party (D or DEM for Democratic Party).
2. `party_labels_cleaned.csv` takes the cleaned party labels and maps them onto a standard set of full-name labels by year and label. This is necessary because symbols and party names aren't unique across years.
3. `ny_general_elections.csv` fill in missing data due to the completely insane way the NY presidential election data is reported - for some (but not all) candidates, each party's collection of votes is only partially reported (either the vote count _or_ vote percentage), alongside a party label called "COMBINED TOTAL". This file fills in the missing percentages and votes. It keeps the COMBINED TOTAL votes as well for reproducibility purposes, though they're filtered out in `build.R` because they're redundant and - to be completely honest - pretty obnoxious.

The three CSV files above were built semi-manually in a spreadsheet.
In general spreadsheets are nightmares for reproducibility, but in this case they were the most convenient way to clean up the data properly.
I worked hard to make sure there aren't any hidden assumptions in them: each CSV file has a "notes" column that describes the assumptions and alterations I made, particularly the judgement calls.
My hope is that they're clear enough to rebuild or alter if they don't properly suit your needs.

To reconstruct them, `ny_general_elections.csv` and `party_cleanup.csv` are trivial to seed from the original data (calls to `select( ... ) %>% distinct( ... )` are pretty much all you need).
The party labels aren't trivial, so there's a script that dumps the "seed" CSV I used to start the alterations: `dump_party_labels.csv`, which creates a file `party_labels.csv` that you can then load into a spreadsheet and clean however you'd like.
Keep in mind that if you change the schema of these auxiliary CSV files you might need to also change any associated code in `build.R` that uses them.

Finally, there are some mildly useful and not mildly sarcastic notes in `notes.md`.
I used them to map out what the final dataset looks like and figure out what the inputs should be. 

## Why R?

Most of the heavy lifting here is done in R.
R's not usually my first choice for projects, but in this case I found the [tidyverse](http://tidyverse.org/) packages invaluable.
I highly recommend checking out `build.R` to see just how powerful these tools are on very messy real-world data.