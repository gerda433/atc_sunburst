# PROJECT RULES - ATC Sunburst Pipeline

## 🎯 **Pipeline Structure Preference**

### **RULE: Use Simple Sequential R Scripts**

**Preferred Structure:**
```
├── prepare_data.R    # Step 1: Data preparation
├── process_data.R    # Step 2: Data processing  
├── run_app.R         # Step 3: Application
└── R/functions.R     # Utility functions only
```

**NOT Preferred:**
```
├── R/01_data_preparation.R
├── R/02_data_processing.R
├── R/03_shiny_app.R
├── R/pipeline.R
└── R/functions.R
```

### **Key Principles:**

1. **Sequential Scripts**: Each script does one thing and runs in order
2. **Simple Source Commands**: Users run `source("script.R")` - no complex function calls
3. **Self-Contained**: Each script loads its own packages and dependencies
4. **No Over-Engineering**: Avoid complex pipeline orchestration or wrapper functions
5. **RStudio-Friendly**: Scripts work naturally in RStudio environment

### **User Experience:**

**What Users Should Do:**
```r
source("prepare_data.R")
source("process_data.R") 
source("run_app.R")
```

**What Users Should NOT Have To Do:**
```r
source("R/pipeline.R")
run_atc_pipeline(skip_data_prep = FALSE, skip_processing = FALSE, run_app = TRUE)
```

### **File Naming:**

- **Use descriptive names**: `prepare_data.R`, `process_data.R`, `run_app.R`
- **Avoid prefixes**: No `01_`, `02_`, `03_` numbering
- **Keep it simple**: Clear, obvious purpose from filename

### **Code Organization:**

- **Minimal Functions**: Only create functions when absolutely necessary
- **Inline Processing**: Keep data processing steps inline, not wrapped in functions
- **Clear Comments**: Explain what each section does, not how functions work
- **No Redundancy**: Don't save intermediate files that aren't used

### **Documentation:**

- **Simple Instructions**: "Run these 3 scripts in order"
- **RStudio-Focused**: Emphasize RStudio usage over command line
- **Step-by-Step**: Clear sequential process
- **No Complex Options**: Avoid multiple ways to run the same thing

### **Why This Approach:**

1. **Familiar to R Users**: Matches traditional R workflow
2. **Easy to Debug**: Can run scripts individually to test
3. **Transparent**: Users can see exactly what each step does
4. **Maintainable**: Simple structure is easier to modify
5. **No Learning Curve**: R users immediately understand how to use it

### **Anti-Patterns to Avoid:**

- ❌ Complex pipeline orchestration
- ❌ Multiple wrapper functions
- ❌ Command-line arguments
- ❌ Over-documentation with roxygen2
- ❌ Modular function-based architecture
- ❌ Redundant intermediate files
- ❌ Complex error handling with tryCatch everywhere

### **Success Criteria:**

A good pipeline should feel like:
- "Just run these 3 scripts in order"
- "Each script does one clear thing"
- "I can understand what's happening"
- "It works the way I expect R scripts to work"

---

**Remember**: The user prefers simple, traditional R workflows over complex, over-engineered solutions. Keep it straightforward and familiar.
