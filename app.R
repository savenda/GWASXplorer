## Check for missing packages and install if needed
list.of.packages <- c("tidyverse", "dplyr", "shiny", "openxlsx")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

## Load libraries
library("tidyverse")
library("dplyr")
library("shiny")
library("openxlsx")

## Load database for GWAS information
GWAS.df <- read.table(
                      #file = "DB/gwas_catalog_v1.0.2-associations_e93_r2018-12-21.tsv",
                      unz("DB/GWAScat.zip", "GWAScatalog.tsv"),
                      header = T,
                      sep = "\t",
                      stringsAsFactors = F, quote = "")

## Change PValue to string, for compatibility whit APP display
GWAS.df$PVALUE <- as.character(GWAS.df$PVALUE)

# Define UI for dataset viewer app ----
ui <- fluidPage(
  
  # App title ----
  titlePanel("GWASXplorer v0.4"),
  
  # Sidebar layout with a input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(
      
      # Input: Text for introducing a search term ----
      # Note: Changes made to the search term in the textInput control
      # are updated in the output area immediately as you type
      textInput(inputId = "term_of_interest",
                label = "Search Term:", value = "DRD2"),
      
      # Output: Formatted text for caption, this will report number of hits for search term ----
      h3(textOutput("number_of_hits", container = span)),
      
      # Button
      downloadButton("downloadData.xlsx", "Download xlsx")
      
    ),
    
    # Main panel for displaying outputs ----
    mainPanel(

      # Output: HTML table with requested number of observations ----
      dataTableOutput("view")
      
    )
  )
)

# Define server logic to summarize and view selected dataset ----
server <- function(input, output) {
  
  # Show the first "n" observations ----
  output$view <- renderDataTable({
    
    ## Use fixed function to ignore case in the search term (thus, ignoring case check during search from user)
    search_term <- fixed(input$term_of_interest, ignore_case=TRUE)
    
    ## built in lock to avoid empty search term bug
    ifelse(search_term == "", search_term <- " Empty Search Term ", search_term <- search_term)
    
    GWAS.df %>% filter( str_detect(REPORTED_GENE, search_term)
                            | str_detect(MAPPED_GENE, search_term)
                            | str_detect(DISEASE_TRAIT, search_term)
                        ) %>%
      select(MAPPED_TRAIT, DISEASE_TRAIT, PVALUE,
             REPORTED_GENE, MAPPED_GENE, CONTEXT,
             CHR_ID, CHR_POS, STRONGEST_SNP_RISK_ALLELE,
             RISK_ALLELE_FREQUENCY,
             #STUDY,
             LINK)
  })
  
  # Create caption for number_of_hits----
  # The output$number_of_hits is computed based on changes to the resuls dataframe
  output$number_of_hits <- renderText({
    
    ## Use fixed function to ignore case in the search term (thus, ignoring case check during search from user)
    search_term <- fixed(input$term_of_interest, ignore_case=TRUE)
    
    ## built in lock to avoid empty search term bug
    ifelse(search_term == "", search_term <- " Empty Search Term ", search_term <- search_term)
    
    paste0(
      GWAS.df %>% filter( str_detect(REPORTED_GENE, search_term)
                          | str_detect(MAPPED_GENE, search_term)
                          | str_detect(DISEASE_TRAIT, search_term)
      ) %>% nrow(),
      " Hits for '",search_term,"'")
  })
  
  # Downloadable csv of selected dataset ----
  output$downloadData.xlsx <- downloadHandler(
    filename = "default_filename.tsv",
    content = function(file) {
      
      ## Use fixed function to ignore case in the search term (thus, ignoring case check during search from user)
      search_term <- fixed(input$term_of_interest, ignore_case=TRUE)
      
      ## built in lock to avoid empty search term bug
      ifelse(search_term == "", search_term <- " Empty Search Term ", search_term <- search_term)
      
      GWAS.df %>% filter( str_detect(REPORTED_GENE, search_term)
                          | str_detect(MAPPED_GENE, search_term)
                          | str_detect(DISEASE_TRAIT, search_term)
      ) %>%
        select(MAPPED_TRAIT, DISEASE_TRAIT, PVALUE,
               REPORTED_GENE, MAPPED_GENE, CONTEXT,
               CHR_ID, CHR_POS, STRONGEST_SNP_RISK_ALLELE,
               RISK_ALLELE_FREQUENCY,
               #STUDY,
               LINK) %>%
        write.xlsx(file, asTable = TRUE)
    }
  )
  
}

# Create Shiny app ----
shinyApp(ui = ui, server = server)