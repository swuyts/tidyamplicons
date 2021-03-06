
make_tidyamplicons <- function(samples, taxa, abundances) {

  # remove abundances of zero
  abundances <- abundances %>%
    filter(abundance > 0)

  # make tidyamplicons (ta) object
  ta <- list(
    samples = samples,
    taxa = taxa,
    abundances = abundances
  )
  class(ta) <- "tidyamplicons"

  # make sure that all tables contain the same unique
  # taxa and samples, and return ta object
  ta %>%
    process_abundance_selection() %>%
    process_sample_selection() %>%
    process_taxon_selection()

}

# converts a phyloseq object to a tidyamplicons object
# the plyloseq object should contain absolute abundances
tidy_phyloseq <- function(ps) {

  # convert sample data
  samples <- sample_data(ps)@.Data %>%
    `names<-`(sample_data(ps)@names) %>%
    do.call(what = tibble) %>%
    mutate(sample = sample_data(ps)@row.names)

  # convert taxon table
  taxa <- tax_table(ps)@.Data %>%
    as_tibble() %>%
    mutate(taxon = tax_table(ps) %>% row.names())

  # make sure that taxa are rows in taxon table
  if (! taxa_are_rows(ps)) otu_table(ps) <- t(otu_table(ps))

  # convert taxon table
  abundances <- otu_table(ps)@.Data %>%
    as_abundances(taxa_are_columns = ! taxa_are_rows(ps))

  # make and return tidyamplicons object
  make_tidyamplicons(
    samples = samples,
    taxa = taxa,
    abundances = abundances
  )

}

as_phyloseq <- function(ta) {

  if ("phyloseq" %in% class(ta)) return(ta)

  otu_table <- ta$abundances %>%
    spread(key = taxon, value = abundance, fill = 0) %>%
    `attr<-`("class", "data.frame") %>%
    `rownames<-`(.$sample) %>%
    select(- sample) %>%
    as.matrix() %>%
    otu_table(taxa_are_rows = F)

  sample_data <- ta$samples %>%
    `attr<-`("class", "data.frame") %>%
    `rownames<-`(.$sample) %>%
    select(- sample) %>%
    sample_data()

  tax_table <- ta$taxa %>%
    `attr<-`("class", "data.frame") %>%
    `rownames<-`(.$taxon) %>%
    select(- taxon) %>%
    as.matrix() %>%
    tax_table()

  phyloseq(otu_table, sample_data, tax_table)

}
