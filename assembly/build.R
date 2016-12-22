# The goal of this script is to use the existing candidate data and produce a 
# tidy dataset with the following columns:

# | column             | description                                              |
# |--------------------|----------------------------------------------------------|
# | `year`             | The election year.                                       |
# | `state`            | The state abbreviation.                                  |
# | `chamber`          | Either "P", "S", or "H".                                 |
# | `district`         | The district, "S" if Senate, "P" if President.           |
# | `election`         | `primary`, `primary_runoff`, `general`, `general_runoff` |
# | `name`             | The name of the candidate.                               |
# | `party`            | The political party of the candidate.                    |
# | `vote`             | Number of votes.                                         |
# | `pct`              | Vote percentage for their race.                          |
# | `incumbent`        | `TRUE` if the candidate is incumbent, `FALSE` otherwise. |
# | `write_in`         | Whether the candidate is a write-in candidate.           |
# | `ballot_modifier`  | `independent` or `unenrolled` or NA.                     |

# The inputs are:
# congress/results.csv  (2000, 2002, 2004, 2006, 2008, 2010, 2012, 2014)
# president/results.csv (2000, 2004, 2008, 2012)

library(tidyverse)
library(stringr)

# ******* CONGRESS INPUTS ******* #

# This makes sure we get the datatypes right when we read the files.
# Some of the columns in some of the files are all NA, so readr interprets them
# incorrectly as characters. This forces them to be interpreted as the correct
# data type.
congress.spec <- cols(
  year = col_integer(),
  date = col_character(),
  chamber = col_character(),
  state = col_character(),
  district = col_character(),
  fec_id = col_character(),
  incumbent = col_character(),
  candidate_last = col_character(),
  candidate_first = col_character(),
  candidate_suffix = col_character(),
  candidate_name = col_character(),
  party = col_character(),
  primary_votes = col_integer(),
  primary_pct = col_double(),
  primary_unopposed = col_character(),
  runoff_votes = col_integer(),
  runoff_pct = col_double(),
  general_votes = col_integer(),
  general_pct = col_double(),
  general_unopposed = col_character(),
  general_runoff_votes = col_integer(),
  general_runoff_pct = col_double(),
  general_combined_party_votes = col_character(),
  general_combined_party_pct = col_character(),
  general_winner = col_character(),
  notes = col_character())

# Read the files individually with the correct datatypes.
congress.2000 <- read_csv('api/2000/congress/results.csv',
                          col_types=congress.spec)
congress.2002 <- read_csv('api/2002/congress/results.csv',
                          col_types=congress.spec) %>%
  # Drop candidate_name because it's empty.
  select(-candidate_name) %>%
  # Reconstruct it from candidate_last and candidate_first.
  # Note that there are no candidate suffixes so we won't worry about those.
  unite(candidate_name, candidate_last, candidate_first, sep=', ') 

congress.2004 <- read_csv('api/2004/congress/results.csv',
                          col_types=congress.spec)
congress.2006 <- read_csv('api/2006/congress/results.csv',
                          col_types=congress.spec)
congress.2008 <- read_csv('api/2008/congress/results.csv',
                          col_types=congress.spec)
congress.2010 <- read_csv('api/2010/congress/results.csv',
                          col_types=congress.spec)
congress.2012 <- read_csv('api/2012/congress/results.csv',
                          col_types=congress.spec)
congress.2014 <- read_csv('api/2014/congress/results.csv',
                          col_types=congress.spec)

# Now union all of the congress results into a single frame.
congress.raw <- congress.2000  %>%
  union_all(congress.2002) %>%
  union_all(congress.2004) %>%
  union_all(congress.2006) %>%
  union_all(congress.2008) %>%
  union_all(congress.2010) %>%
  union_all(congress.2012) %>%
  union_all(congress.2014) %>%
  # Convert the 'incumbent' column into a LOGICAL.
  mutate(incumbent=as.logical(incumbent)) %>%
  # Fix an issue with NY where general_pct isn't filled in.
  group_by(year, chamber, state, district) %>%
  mutate(general_pct = 
           if_else(general_pct == 0.0 & general_votes > 0 & state == "NY",
                   round(general_votes / sum(general_votes, na.rm=TRUE) * 100,
                         digits=2),
                   general_pct)) %>%
  ungroup()

# Read in the party labels.
# This is another file I cleaned up manually. With a spreadsheet. Again, this
# resulted in the years being columns because that makes the data entry easier.
# Thankfully tidyr has our back and makes it simple to re-collapse those columns
# into a better form.
party.labels <- read_csv('party_labels_cleaned.csv') %>%
  # We don't need the notes here.
  select(-notes) %>%
  # Collapse the year-labeled columns.
  gather("year", "name", `2000`:`2014`) %>%
  # Drop any labels that don't have a corresponding name for that year.
  filter(!is.na(name)) %>%
  # Convert the year to integer and rename `name`.
  mutate(year=as.integer(year), party_name=name) %>%
  # Drop original `name`.
  select(-name)

# The party labels are pretty messy - `party_cleanup.csv` is a
# hand-built file designed to join against the congress dataset to standardize
# the labels. 
party.cleanup <- read_csv('party_cleanup.csv') %>%
  # It was much simpler to break non_partisan / independent / unenrolled into
  # their own columns when entering the data, but since they're mutually 
  # exclusive they need to be collapsed.
  # A well placed `case_when` would knock this out easily, but it doesn't
  # work with `mutate` as of this writing. Default is NA.
  mutate(
    ballot_modifier=
      if_else(non_partisan | independent, "independent", NA_character_)) %>%
  mutate(
    ballot_modifier=if_else(unenrolled, "unenrolled", ballot_modifier)) %>%
  select(-non_partisan, -independent, -unenrolled, -notes)

# ******* CONGRESS TIDYING ******* #
# Now tidy up the congress data set.
# Steps are: 
# 1. Get only the relevant columns
# 2. Perform the tidying on the election type.
# 3. Remove any NA votes.
# 4. Standardize the district label for the Senate.
# 5. Join against the party cleanup frame to standardize the party labels.
# 6. Join against the party labels to replace party labels with actual names.
congress.tidy <- congress.raw %>%
  # Grab the relevant columns.
  select(year,
         chamber,
         state,
         district,
         incumbent,
         name=candidate_name,
         party,
         # We'll use the dot as a separator for a call to `spread` later.
         primary.vote=primary_votes,
         primary.pct=primary_pct,
         primary_runoff.vote=runoff_votes,
         primary_runoff.pct=runoff_pct,
         general.vote=general_votes,
         general.pct=general_pct,
         general_runoff.vote=general_runoff_votes,
         general_runoff.pct=general_runoff_pct) %>%
  # Begin the tidying by piling all of the results into a single numeric column.
  gather('election', 'result', 
         primary.vote, 
         primary.pct, 
         primary_runoff.vote,
         primary_runoff.pct,
         general.vote,
         general.pct,
         general_runoff.vote,
         general_runoff.pct) %>%
  # Remove any null results. Some of these will come back later, but it makes
  # things a little faster.
  filter(!is.na(result)) %>%
  # Now split the election column values on the dot. The right of the dot 
  # indicates the election, the left indicates what the result measure is.
  separate('election', c('election','measure'), sep='\\.') %>%
  # For whatever reason there are duplicate entries for certain elections.
  # One of them is zero percent / votes, the other is the actual result.
  # Easiest thing to do is take the max, but sum works here too. I verified
  # this by looking at each of the dupes and checked that the max and sum gave
  # the same number.
  group_by(year, 
           chamber, 
           state, 
           district, 
           incumbent, 
           name, 
           party, 
           election, 
           measure) %>%
  summarize(result=max(result)) %>%
  ungroup() %>%
  # Now we break `measure` into two columns, one for the percent and the other
  # for the raw vote.
  spread(measure, result) %>%
  # Fix the vote data type.
  mutate(vote=as.integer(vote)) %>%
  # Join to the cleaned party labels.
  inner_join(party.cleanup, by="party") %>%
  # Now replace "party" with "party_cleaned"
  mutate(party=str_trim(party_cleaned, side="both")) %>%
  # Drop original party_cleaned.
  select(-party_cleaned) %>%
  # Join to the cleaned party names.
  left_join(party.labels, by=c("party"="abbrev", "year")) %>%
  # Replace the `party` field with the names, with a fallback to the party label
  # if there isn't an identifier.
  mutate(party=coalesce(party_name, party)) %>%
  # Remove the `party_name` field since it's redundant.
  select(-party_name)

# *******  CONGRESS SPOT FIXES ******* #

# 1. Bud Shuster is a Republican, but he is sometimes listed as "D/R".
#    See https://en.wikipedia.org/wiki/Bud_Shuster
congress.tidy[congress.tidy$name == "Shuster, Bud" & 
              congress.tidy$party == "D/R",]$party <- "Republican"

# 2. Peter Welch is a Democrat, but he is sometimes listed as "D/R".
#    See  https://en.wikipedia.org/wiki/Peter_Welch .
congress.tidy[congress.tidy$name == "Welch, Peter" &
              congress.tidy$party == "D/R",]$party <- "Democratic"

# ******* PRESIDENT INPUTS ******* #
president.2000.general <- 
  read_csv('api/2000/president/general_election_results.csv')
president.2004.general <- 
  read_csv('api/2004/president/general_election_results.csv')
president.2008.general <-
  read_csv('api/2008/president/general_election_results.csv')
president.2012.general <-
  read_csv('api/2012/president/general_election_results.csv')

president.general.raw <- president.2000.general %>%
  union_all(president.2004.general) %>%
  union_all(president.2008.general) %>%
  union_all(president.2012.general) %>%
  # Grab only the columns we need.
  select(year,
         chamber,
         state,
         incumbent,
         name=candidate_name,
         party,
         vote=general_votes,
         pct=general_pct) %>%
  # Add the election type.
  mutate(election="general")

president.primary.spec <- cols( 
  year = col_integer(),
  date = col_character(),
  chamber = col_character(),
  state = col_character(),
  district = col_character(),
  fec_id = col_character(),
  incumbent = col_character(),
  candidate_last = col_character(),
  candidate_first = col_character(),
  candidate_suffix = col_character(),
  candidate_name = col_character(),
  party = col_character(),
  primary_votes = col_integer(),
  primary_pct = col_double(),
  primary_unopposed = col_character(),
  runoff_votes = col_character(),
  runoff_pct = col_character(),
  general_votes = col_character(),
  general_pct = col_character(),
  general_unopposed = col_character(),
  general_runoff_votes = col_character(),
  general_runoff_pct = col_character(),
  general_combined_party_votes = col_character(),
  general_combined_party_pct = col_character(),
  general_winner = col_character(),
  notes = col_character())

president.2000.primary <- 
  read_csv('api/2000/president/primary_election_results.csv',
           col_types=president.primary.spec)
president.2004.primary <-
  read_csv('api/2004/president/primary_election_results.csv',
           col_types=president.primary.spec)
president.2008.primary <-
  read_csv('api/2008/president/primary_election_results.csv',
           col_types=president.primary.spec)
president.2012.primary <-
  read_csv('api/2012/president/primary_election_results.csv',
           col_types=president.primary.spec)

president.primary.raw <- president.2000.primary %>%
  union_all(president.2004.primary) %>%
  union_all(president.2008.primary) %>%
  union_all(president.2012.primary) %>%
  select(year, 
         chamber, 
         state, 
         incumbent, 
         name=candidate_name, 
         party,
         vote=primary_votes,
         pct=primary_pct) %>%
  mutate(election="primary", district="P")

president.raw <- union_all(president.primary.raw, president.general.raw) %>%
  mutate(incumbent=as.logical(incumbent))
  
# So the state of NY has done something incredibly obnoxious and reported
# individual party totals and a COMBINED TOTAL for the parties. It gets even
# better because some of the years have the total votes on COMBINED TOTAL and
# zeros for the sub-parties, while others have the percentage only on
# COMBINED TOTAL and the raw votes on the sub-parties.
# The fix is to read a helper that was manually constructed and union that
# to president.raw. It's possible to construct the helper year-by-year with 
# code, but it's actually fewer lines than doing it in a spreadsheet. I did
# mark in the `notes` column what was manually altered so the results are 
# fully reproducible.
ny.general.elections <- read_csv('ny_general_elections.csv') %>%
  mutate(incumbent=as.logical(incumbent)) %>%
  # Take out the columns we don't need.
  select(-effective_vote, 
         -election_total_vote, 
         -notes) %>%
  # Remove the COMBINED TOTAL values - we only need those for reproducibility.
  filter(party != "COMBINED TOTAL")

president.tidy <- president.raw %>%
  # Remove all NY general election values.
  filter(!(state == "NY" & election == "general")) %>%
  # Add the corrected values.
  union_all(ny.general.elections) %>%
  # Set the district to "P".
  mutate(district = "P") %>% 
  # Now join up to the party cleaner.
  inner_join(party.cleanup, by="party") %>%
  # Swap out the party value for the cleaned one.
  mutate(party=str_trim(party_cleaned, side="both")) %>%
  # Drop the party_cleaned column since it's duplicated.
  select(-party_cleaned) %>%
  # Now that the party labels are clean, put the party names in.
  left_join(party.labels, by=c("party" = "abbrev", "year")) %>%
  # Swap out party with the party name, but only if there's a corresponding
   # party name.
  mutate(party=coalesce(party_name, party)) %>%
  # Drop the party_name column now that it's been used.
  select(-party_name)

# F I N A L L Y end this awful business.
fec.tidy <- congress.tidy %>% 
  union_all(president.tidy) %>%
  # Fix up the district labels.
         # First, extract just the district labels.
         # These can be H, S, P, or digits. Some got read in as decimals, but
         # This str_extract fixes that by matching the digits to the left of
         # the decimal points.
  mutate(district_cleaned=str_extract(district, '[0-9HSP]+'), 
         # Special elections happen during unexpired terms. This is denoted with
         # "Unexpired" being present somewhere in the district label, or with
         # an asterisk.
         unexpired_term=str_match(toupper(district), 'UN|\\*'), 
         # If it's not an unexpired term (i.e. the regex above didn't match),
         # then it's not a special election.
         special_election=!is.na(unexpired_term),
         # Finally, replace the original district label with the cleaned one, 
         # and drop a leading zero in front of the numeric district labels that
         # only have one digit.
         district=str_replace(district_cleaned, '^(\\d)$','0\\1'),
         election=if_else(special_election, 
                          paste('special', election, sep='-'), 
                          election)) %>%
  # Drop the auxiliary columns 
  select(-unexpired_term, -district_cleaned, -special_election) %>%
  # Sort the rows.
  arrange(year, chamber, district, election, name) %>%
  # Reorder the columns for ease of use.
  select(year,
         state,
         chamber,
         district,
         election,
         name,
         party,
         vote,
         pct,
         incumbent,
         write_in,
         ballot_modifier)

# ... and we're freaking done.
write_csv(fec.tidy, '../fec_tidy.csv', na="")