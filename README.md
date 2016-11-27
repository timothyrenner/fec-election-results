# FEC Data

This is a dataset containing all election data for the House of Representatives, Senate, and Presidency from 2000 - 2014 (I do have plans to expand it, but it will be slow going).
It's pretty well established that most government data sucks these days; hopefully this dataset doesn't.
It's been extensively cleaned to standardize the names of the political parties and break apart various ballot modifiers like write-ins and un-enrolled candidates.
The data has also been arranged in a [tidy](http://vita.had.co.nz/papers/tidy-data.pdf) format, so it plays very nicely with the `tidyr` and `dplyr` packages in R.
Obviously it works fine with `pandas` as well.

## Dictionary
Each row represents a single candidate on a ballot for an election (primary or general), with both a vote count and percent.

| column            | type    | description                                                                                                                                 |
|-------------------|---------|---------------------------------------------------------------------------------------------------------------------------------------------|
| `year`            | `int`   | The year of the election.                                                                                                                   |
| `state`           | `str`   | The state abbreviation.                                                                                                                     |
| `chamber`         | `str`   | The chamber for the election: "P", "S", or "H".                                                                                             |
| `district`        | `str`   | The district ("H" for bundled House results, "S" for Senate, and "P" for president).                                                        |
| `election`        | `str`   | The election, either "primary" or "general", with "_runoff" appended for runoff elections and "special-" prepended for off-cycle elections. |
| `name`            | `str`   | The name of the candidate (last, first MI).                                                                                                 |
| `party`           | `str`   | The name of the candidate's political party.                                                                                                |
| `vote`            | `int`   | The number of votes.                                                                                                                        |
| `pct`             | `float` | The percent of votes.                                                                                                                       |
| `incumbent`       | `bool`  | Whether the candidate is an incumbent.                                                                                                      |
| `write_in`        | `bool`  | Whether the candidate was a ballot write in.                                                                                                |
| `ballot_modifier` | `str`   | Modifications to the ballot - "independent" or "unenrolled".                                                                                |

## Examples

Here are a few examples of how to work with this dataset.
The key idea behind the tidy data format isn't that it's in its most useful form, but that it can easily be shaped into a useful form for whatever you're doing with it.

```r
library(tidyverse)

fec.tidy <- read_csv('fec_tidy.csv')
```

Grab the winners of the general election for president for each year.

```r
fec.tidy %>% filter(election == "general", chamber =="president") %>%
    select(year, name, vote) %>%
    group_by(year, name) %>%
    summarize(vote=sum(vote)) %>%
    group_by(year) %>%
    mutate(vote_rank=row_number(desc(vote))) %>%
    filter(vote_rank == 1) %>% 
    select(-vote_rank) %>%
    ungroup()

# A tibble: 4 x 3
   year            name     vote
  <int>           <chr>    <int>
1  2000        Gore, Al 50794611
2  2004 Bush, George W. 59256278
3  2008   Obama, Barack 69194659
4  2012   Obama, Barack 65915795
```

Well look at that 2000 result.
Note the electoral college votes aren't in this dataset.
I think it would be possible to put them in as well with a different "election" value, but I haven't decided if that's a better idea than just giving them their own dataset.

Suppose we wanted to look at voter turnout for the Democrat and Republican party Senate races as a function of year:

```r
fec.tidy %>% filter(party == "Democratic" | party == "Republican", 
                    election == "general", 
                    chamber == "S") %>% 
    select(year, party, vote) %>% 
    group_by(year, party) %>% 
    summarize(vote=sum(vote)) %>% 
    spread(year, vote)

# A tibble: 2 x 9
       party     2000     2002     2004     2006     2008     2010     2012     2014
*      <chr>    <int>    <int>    <int>    <int>    <int>    <int>    <int>    <int>
1 Democratic 35430199 18753090 48946623 32758253 33284960 28609182 53013636 18307110
2 Republican 36730057 21604501 39920966 26510902 29502160 32682570 40889718 22489292
```

As a final example, let's look at the candidate with the most write-in votes.

```r
fec.tidy %>% filter(write_in == TRUE) %>% 
    mutate(rnk = row_number(desc(vote))) %>% 
    filter(rnk == 1) %>% 
    select(year, 
          state, 
          chamber, 
          district, 
          election, 
          name, 
          party, 
          vote, 
          pct)

# A tibble: 1 x 9
   year state chamber district election                    name      party   vote      pct
  <int> <chr>   <chr>    <chr>    <chr>                   <chr>      <chr>  <int>    <dbl>
1  2006    OH       H       06  general Wilson, Charles A., Jr. Democratic 135628 62.07913
```

This looks like bad data - has a write in candidate actually ever _won_?
Sort of.
It turns out that Charles Wilson (seen above) didn't get the required number of signatures in time to appear on the primary ballot and launched a massive effort during the Democratic primaries, where he won with a write-in.
He then went on to defeat his Republican opponent in the general election.
So technically he won the primary as a write-in Democrat.
While I might not categorize him as a write in for the general election (since he wasn't written in for that one), I can see the case for it.
Read more about this madness on his [Wikipedia page](https://en.wikipedia.org/wiki/Charlie_Wilson_(Ohio_politician)).

A lot of this data is inherently messy because the subject matter's messy.
I've tried to make the building of the dataset as clear as possible so that if you want to modify the assumptions it's pretty easy.

## Building

This dataset can be fully rebuilt from scratch if you feel like some of the assumptions or structural choices need to be changed.
Detailed instructions are in the `README.md` file in the `assembly` directory.

## Roadmap

The primary thing on the roadmap is to get more data.
The FEC website has data going all the way back into the '80s, but it will be hard to clean since it's mostly in Excel and PDFs.
I don't have a firm timeline for any of this but I'd like to ideally add an election every 3-6 months.

## Contributions

Obviously if there's anything off about the data file an issue.
I've done my best, but I'm bound to have missed some stuff (see weird write-in candidate example above).
If it's not something that's blatantly wrong it would be helpful to provide a link so I can document the issue when I fix it.
You'll see a lot of links if you poke around in the code.
Obviously Wikipedia is a good choice, but I've also found [Ballotpedia](https://ballotpedia.org/Main_Page) to be super helpful.

If you submit a PR I'm happy merge it as long as there's justification (via reference links) when necessary and as long as it's complete (i.e. I won't take _just_ the Senate results for 1996 - I'll need Senate, House and President).