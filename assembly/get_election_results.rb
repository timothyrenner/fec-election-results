require "fec_results_generator"

years = [2000, 2002, 2004, 2006, 2008, 2010, 2012, 2014]

years.each do |year|
    puts("Year: #{year}.")

    # Grab congress and the summary.
    g = FecResultsGenerator::JsonGenerator.new(:year => year)
    g.congress
    g.summary
    
    # If the year is a multiple of 4, grab the presidential results.
    if year % 4 == 0
        g.president
    end # Close if statement on president.

end # Close loop over years (year).