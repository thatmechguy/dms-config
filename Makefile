.PHONY: install backup clean help

help:
	@echo "QuickShell Desktop Configuration"
	@echo ""
	@echo "Usage:"
	@echo "  make install    - Install configuration"
	@echo "  make backup    - Backup current configuration"
	@echo "  make clean     - Remove installed configuration"
	@echo "  make status    - Show installation status"

INSTALL_DIR := $(HOME)/.config/dms-config
QUICKSHELL_DIR := $(HOME)/.config/quickshell
HYPR_DIR := $(HOME)/.config/hypr

install:
	@echo "Installing QuickShell Desktop configuration..."
	@chmod +x install.sh
	@./install.sh

backup:
	@echo "Creating backup..."
	@mkdir -p $(HOME)/.config/dms-backup-$$(date +%Y%m%d-%H%M%S)
	@if [ -d "$(QUICKSHELL_DIR)" ]; then cp -r "$(QUICKSHELL_DIR)" "$(HOME)/.config/dms-backup-$$(date +%Y%m%d-%H%M%S)/"; fi
	@if [ -d "$(HYPR_DIR)" ]; then cp -r "$(HYPR_DIR)" "$(HOME)/.config/dms-backup-$$(date +%Y%m%d-%H%M%S)/"; fi
	@echo "Backup complete!"

clean:
	@echo "Removing installed configuration..."
	@rm -rf "$(QUICKSHELL_DIR)"
	@rm -rf "$(HYPR_DIR)"
	@echo "Clean complete! Run 'make install' to reinstall."

status:
	@echo "QuickShell Desktop Configuration Status"
	@echo ""
	@echo "Installed files:"
	@if [ -d "$(QUICKSHELL_DIR)" ]; then \
		echo "  ✓ QuickShell: $(QUICKSHELL_DIR)"; \
		ls -1 "$(QUICKSHELL_DIR)" 2>/dev/null | sed 's/^/    • /'; \
	else \
		echo "  ✗ QuickShell: Not installed"; \
	fi
	@echo ""
	@if [ -d "$(HYPR_DIR)" ]; then \
		echo "  ✓ Hyprland: $(HYPR_DIR)"; \
		ls -1 "$(HYPR_DIR)"/*.conf 2>/dev/null | sed 's/.*\//    • /'; \
		ls -1 "$(HYPR_DIR)/scripts/"*.sh 2>/dev/null | sed 's/.*\//    • /'; \
	else \
		echo "  ✗ Hyprland: Not installed"; \
	fi
	@echo ""
	@echo "Wallpaper directory:"
	@if [ -d "$(HOME)/Pictures/Wallpapers" ]; then \
		echo "  ✓ $(HOME)/Pictures/Wallpapers"; \
		echo "    ($(ls -1 $(HOME)/Pictures/Wallpapers 2>/dev/null | wc -l) wallpapers)"; \
	else \
		echo "  ✗ $(HOME)/Pictures/Wallpapers (not created)"; \
	fi
