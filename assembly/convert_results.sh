# Congress first.
for file in $(ls api/*/congress/results.json); do
    echo "Converting $file."
    ./flat_json_to_csv.sh $file
done

# Now president general election.
for file in $(ls api/*/president/general_election_results.json); do
    echo "Converting $file."
    ./flat_json_to_csv.sh $file
done

# Finally, presidential primaries.
for file in $(ls api/*/president/primary_election_results.json); do
    echo "Converting $file."
    ./flat_json_to_csv.sh $file
done