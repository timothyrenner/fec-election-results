# FEC Results Data

These files were pulled from the FEC using the script `get_election_results.rb`, which depends on the `fec_results_generator` gem.
You can install that gem by cloning [this repo](https://github.com/openelections/fec_results_generator) and running `gem install fec_results_generator` in that project's root directory.

## Reading the Files

So these files are actually _nested_ JSON strings - with one overarching JSON list containing JSON string elements.

> Yo dawg, I heard you needed some JSON.
>
> So I JSON'd you some JSON wrapped in JSON.

To convert these JSON'd JSON files into the substantially more useful CSV format, we can use [jq](https://stedolan.github.io/jq/).

```bash
# Cat the file, then splat the array. Grab one element, parse it again,
# and grab the keys, making it a csv.
cat file.json | \
jq --raw-output '.[]' | \
head -n 1 | \
jq --raw-output 'keys_unsorted | @csv' > file.csv

# Cat the file, then splat the array. Grab all of the values with `.[]`, but
# capture them into an array, then append to the file we just made. 
cat file.json | \
jq --raw-output '.[]' | \
jq --raw-output '[.[]] | @csv' >> file.csv
```

... and that's how we do this with no python.

## File Descriptions

Note that for 2014 `summary/` we only have `general_election_votes.json` and `party_labels.json`.
There is a bug in the client.

Files in `summary/`:

- `chamber_votes_by_party.json`: Contains the votes for Congress, by party (with all third parties as "Other") and election (primary and general) (flat). 2010 has an extra column.
- `congressional_votes_by_election.json`: Contains data for the number of votes in both the general and primary elections for the house and Senate seats by state (flat). 2010 has an extra column.
- `general_election_votes.json`: Total votes by chamber (including president if applicable) and state (flat). 2002 file is empty.
- `general_election_votes_by_party.json`: Total votes across all races by party and state (flat). 2010 has an extra column. 2002 is empty.
- `party_labels.json`: Maps the party codes to the party names (flat).

Files in `congress/`:

- `results.json`: The results (number of votes) at a district level for both the primary and general election campaigns (flat).

Files in `president/`:

- `general_election_results.json`: Results of the general election for president by state and candidate (flat).
- `popular_vote_summary.json`: Empty for 2000. 2004 has one extra column compared to 2008 and 2012.
- `primary_election_results.json`: Primary election results for president by candidate and state (flat).
- `primary_party_summary.json`: Total primary votes by party (flat). Sometimes this is empty. Empty for 2000.
- `state_electoral_and_popular_vote_summary.json`: Electoral and popular votes by state (flat). Sometimes this is empty. Empty for 2000.

### Columns for `summary/chamber_votes_by_party.json`

Recall that there's no data in this file for 2014.

| column                     | sample (2012)  |
|----------------------------|----------------|
| `state` (2010 only)        | "Arizona"      |
| `state_abbrev`             | "AZ"           |
| `democratic_primary_votes` | 307282         |
| `republican_primary_votes` | 487978         |
| `other_primary_votes`      | 988            |
| `democratic_general_votes` | 946994         |
| `republican_general_votes` | 1131663        |
| `other_general_votes`      | 94660          |

### Columns for `sumamry/congressional_votes_by_election.json`

Recall that there's no data in this file for 2014.

| column                 | sample (2012) |
|------------------------|---------------|
| `state` (2010 only)    | "Arizona"     |
| `state_abbrev`         | "AZ"          |
| `senate_primary_votes` | 806497        |
| `senate_general_votes` | 2243422       |
| `house_primary_votes`  | 796248        |
| `house_general_votes`  | 2173317       |

### Columns for `summary/general_election_votes.json`

Okay - this one is totally hosed - some of the off-years have `total_votes` and some of them have `state`, which is actually the same as `state_abbrev`.
Plus, 2012 has `state` instead of `state_abbrev`.

`¯\_(ツ)_/¯`

Presidential years: 2000, 2004, 2008, 2012 - 

| column                                 | sample (2012) |
|----------------------------------------|---------------|
| `state_abbrev` (`state` for 2012)      | "AZ"          |
| `presidential_votes`                   | 2299254       |
| `senate_votes`                         | 2243422       |
| `house_votes`                          | 2173317       |

Non-presidential years: 2004, 2006, 2010, 2014 -
There's not data in this file for 2002.

Here's what they look like for 2010 and 2014

| column         | sample (2014) |
|----------------|---------------|
| `state`        | "AL"          |
| `state_abbrev` | "AL"          |
| `senate_votes` | 818090        |
| `house_votes`  | 1080880       |

Here's what 2006 looks like.

| column         | sample (2006) |
|----------------|---------------|
| `state_abbrev` | "AZ"          |
| `senate_votes` | 1526782       |
| `house_votes`  | 1493150       |
| `total_votes`  | 3019932       |

Here's what I look like

![](https://az616578.vo.msecnd.net/files/responsive/embedded/any/desktop/2016/05/07/635981924299738524-97151994_jim%20bustle.com.jpg)

...ish. 
Either way, we don't need those columns anyway because they contain completely redundant information.

### Columns for `summary/general_election_votes_by_party.json`

Note this file is missing for 2014.
Note this file is empty for 2012.

| column                  | sample (2010) |
|-------------------------|---------------|
| `state` (2010)          | "Arizona"     |
| `state_abbrev`          | "AZ"          |
| `democratic_candidates` | 1303848       |
| `republican_candidates` | 1906125       |
| `other_candidates`      | 196656        |

### Columns for `summary/party_labels`

| column   | sample (2014)     |
|----------|-------------------|
| `abbrev` | "AE"              |
| `name`   | "Americans Elect" |

### Columns for `president/general_election_results.json`

| column                         | sample (2012)     |
|--------------------------------|-------------------|
| `year`                         | 2012              |
| `date`                         | NULL              |
| `chamber`                      | "P"               |
| `state`                        | "AL"              |
| `district`                     | NULL              |
| `fec_id`                       | "P80003353        |
| `incumbent`                    | false             |
| `candidate_last`               | "Romney, Mitt"    |
| `candidate_first`              | "Romney, Mitt"    |
| `candidate_suffix`             | NULL              |
| `candidate_name`               | "Romney, Mitt"    |
| `party`                        | "R"               |
| `primary_votes`                | NULL              |
| `primary_pct`                  | NULL              |
| `primary_unopposed`            | NULL              |
| `runoff_votes`                 | NULL              |
| `runoff_pct`                   | NULL              |
| `general_votes`                | 1255925           |
| `general_pct`                  | 60.54582232982282 |
| `general_unopposed`            | NULL              |
| `general_runoff_votes`         | NULL              |
| `general_runoff_pct`           | NULL              |
| `general_combined_party_votes` | NULL              |
| `general_combined_party_pct`   | NULL              |
| `general_winner`               | true              |
| `notes`                        | NULL              |

### Columns for `president/popular_vote_summary.json`

Not that data is missing for 2000.

| column                 | sample (2004)      |
|------------------------|--------------------|
| `candidate`            | "George W. Bush"   |
| `party` (2004)         | "Republican"       |
| `popular_votes`        | 62040610           |
| `popular_vote_percent` | 0.5073016752545009 |

### Columns for `president/primary_election_results.json`

| column                         | sample (2012)    |
|--------------------------------|------------------|
| `year`                         | 2012             |
| `date`                         | NULL             |
| `chamber`                      | "P"              |
| `state`                        | "AL"             |
| `district`                     | NULL             |
| `fec_id`                       | "P80003338"      |
| `incumbent`                    | true             |
| `candidate_last`               | "Obama, Barack"  |
| `candidate_first`              | "Obama, Barack"  |
| `candidate_suffix`             | NULL             |
| `candidate_name`               | "Obama, Barack"  |
| `party`                        | "D"              |
| `primary_votes`                | NULL             |
| `primary_pct`                  | NULL             |
| `primary_unopposed`            | NULL             |
| `runoff_votes`                 | NULL             |
| `runoff_pct`                   | NULL             |
| `general_votes`                | 241276           |
| `general_pct`                  | 84.1002331896086 |
| `general_unopposed`            | NULL             |
| `general_runoff_votes`         | NULL             |
| `general_runoff_pct`           | NULL             |
| `general_combined_party_votes` | NULL             |
| `general_combined_party_pct`   | NULL             |
| `general_winner`               | NULL             |
| `notes`                        | NULL             |

### Columns for `president/primary_party_summary.json`

Note this file is empty for 2000.

| column        | sample (2012)          |
|---------------|------------------------|
| `party`       | "Republican Party (R)" |
| `total_votes` | 19530335               |

### Columns for `president/state_electoral_and_popular_vote_summary.json`

Note this file is empty for 2000.

| column                       | sample (2012) |
|------------------------------|---------------|
| `state`                      | "AL"          |
| `democratic_electoral_votes` | 0             |
| `republican_electoral_votes` | 9             |
| `democratic_popular_votes`   | 795696        |
| `republican_popular_votes`   | 1255925       |
| `other_popular_votes`        | 22717         |
| `total_votes`                | 2074338       |

### Columns for `congress/results.json`

| column                         | sample (2014)     |
|--------------------------------|-------------------|
| `year`                         | 2014              |
| `date`                         | NULL              |
| `chamber`                      | "S"               |
| `state`                        | "AL"              |
| `district`                     | "S"               |
| `fec_id`                       | "S6AL00195"       |
| `incumbent`                    | true              |
| `candidate_last`               | "Sessions"        |
| `candidate_first`              | "Jeff"            |
| `candidate_suffix`             | NULL              |
| `candidate_name`               | "Sessions, Jeff"  |
| `party`                        | "R"               |
| `primary_votes`                | NULL              |
| `primary_pct`                  | 100               |
| `primary_unopposed`            | true              |
| `runoff_votes`                 | NULL              |
| `runoff_pct`                   | NULL              |
| `general_votes`                | 795606            |
| `general_pct`                  | 97.25164712928895 |
| `general_unopposed`            | false             |
| `general_runoff_votes`         | NULL              |
| `general_runoff_pct`           | NULL              |
| `general_combined_party_votes` | NULL              |
| `general_combined_party_pct`   | NULL              |
| `general_winner`               | true              |
| `notes`                        | NULL              |