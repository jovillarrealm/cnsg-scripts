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
print(recs)
recs <- recs[order(recs$comparisons_number), ]
print(recs)
# scale_x_log10() +
ggplot(recs, aes(x = comparisons, y = user_time)) +
  scale_x_discrete() +
  scale_y_log10() +
  geom_bar(stat = "identity") +
  labs(
    title = "Scatter Plot of log(Comparisons) vs log(User Time)",
    x = "Comparisons (QxR)",
    y = "User Time (s)"
  ) +
  theme_minimal()

# Print the plot explicitly (optional)
print(last_plot())
