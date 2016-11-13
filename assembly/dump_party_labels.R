# This is how I read the party labels from the files to create the basis for
# the `party_labels_cleaned.csv` file.

party.labels <- 
  (read_csv('api/2000/summary/party_labels.csv') %>% mutate(year=2000)) %>%
  union_all(
    (read_csv('api/2002/summary/party_labels.csv') %>% mutate(year=2002))) %>%
  union_all(
    (read_csv('api/2004/summary/party_labels.csv') %>% mutate(year=2004))) %>%
  union_all(
    (read_csv('api/2006/summary/party_labels.csv') %>% mutate(year=2006))) %>%
  union_all(
    (read_csv('api/2008/summary/party_labels.csv') %>% mutate(year=2008))) %>%
  union_all(
    (read_csv('api/2010/summary/party_labels.csv') %>% mutate(year=2010))) %>%
  union_all(
    (read_csv('api/2012/summary/party_labels.csv') %>% mutate(year=2012))) %>%
  union_all(
    (read_csv('api/2014/summary/party_labels.csv') %>% mutate(year=2014))) %>%
  mutate(abbrev=str_trim(coalesce(abbrev, "N-A")),
         name=str_trim(name, side="both")) %>%
  distinct(abbrev, name, year) %>%
  spread(year, name)

write_csv(party_labels, 'party_labels.csv')