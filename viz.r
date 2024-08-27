library(tidyverse, help, pos = 2, lib.loc = NULL)
# library(lintr, help, pos = 3, lib.loc = NULL)
# library(httpgd, help, pos = 4, lib.loc = NULL)
# library(languageserver, help, pos = 5, lib.loc = NULL)
library(ggplot2, help, pos = 6, lib.loc = NULL)
recs <- read.csv(
  file = "/home/jorge/22julia/eDNA-empty/ptester/recs.csv",
  header = TRUE,
  sep = ";"
)

ggplot(recs, aes(x = comparisons_number, y = user_time)) +
  geom_point() +
  labs(
    title = "Scatter Plot of time vs comparisons",
    x = "# of comparisons",
    y = "User time (s)"
  )
