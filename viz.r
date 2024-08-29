library(tidyverse)

# Load the data
recs <- read.csv(
  file = "/home/jorge/22julia/eDNA-empty/ptester/recs.csv",
  header = TRUE,
  sep = ";"
)

# Group, summarize, and sort the data for avg_user_time
recs_sorted_grouped <- recs %>%
  group_by(comparisons) %>%
  summarize(
    avg_user_time = mean(user_time, na.rm = TRUE),
    total_comparisons_number = sum(comparisons_number, na.rm = TRUE)
  ) %>%
  arrange(total_comparisons_number) %>%
  mutate(comparisons = factor(comparisons, levels = comparisons))

# Group, summarize, and sort the data for mrss
recs_sorted_grouped_mrss <- recs %>%
  group_by(comparisons) %>%
  summarize(
    mrss = mean(mrss, na.rm = TRUE),
    total_comparisons_number = sum(comparisons_number, na.rm = TRUE)
  ) %>%
  arrange(total_comparisons_number) %>%
  mutate(comparisons = factor(comparisons, levels = comparisons))

# Plot for avg_user_time
plot_user_time <- ggplot(recs_sorted_grouped, aes(x = comparisons, y = avg_user_time)) +
  geom_bar(stat = "identity") +
  scale_y_log10() +
  labs(
    title = "Plot of log(User Time (s)) by Comparisons",
    x = "Comparisons (QxR)",
    y = "log(Average User Time) (s)"
  ) +
  theme_classic()

# Plot for mrss
plot_mrss <- ggplot(recs_sorted_grouped_mrss, aes(x = comparisons, y = mrss)) +
  geom_bar(stat = "identity") +
  scale_y_log10() +
  labs(
    title = "Plot of log(MRSS (KB)) by Comparisons",
    x = "Comparisons (QxR)",
    y = "log(Maximum Resident Set Size) (KB)"
  ) +
  theme_classic()

# Print both plots explicitly
print(plot_user_time)
print(plot_mrss)
