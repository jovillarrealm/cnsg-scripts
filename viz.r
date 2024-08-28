library(tidyverse)

# Load the data
recs <- read.csv(
  file = "/home/jorge/22julia/eDNA-empty/ptester/recs.csv",
  header = TRUE,
  sep = ";"
)

# Sort by comparisons_number and group by comparisons
recs_sorted_grouped <- recs %>%
  group_by(comparisons) %>%
  summarize(
    avg_user_time = mean(user_time, na.rm = TRUE),
    total_comparisons_number = sum(comparisons_number, na.rm = TRUE),
  ) %>%
  arrange(total_comparisons_number) %>%
  mutate(comparisons = factor(comparisons, levels = comparisons)) # Ensure the order in the plot

# Plot the grouped and sorted data
ggplot(recs_sorted_grouped, aes(x = comparisons, y = avg_user_time)) +
  geom_bar(stat = "identity") +
  scale_y_log10() +
  labs(
    title = "Plot of log(User Time (s)) by Comparisons",
    x = "Comparisons (QxR)",
    y = "log(Average User Time) (s)"
  ) +
  theme_classic()

# Print the plot explicitly (optional)
print(last_plot())
