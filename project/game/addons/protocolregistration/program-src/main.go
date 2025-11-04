package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
)

func main() {
	var register bool
	args := os.Args[1:]

	// Check for --register flag
	if len(args) > 0 && args[0] == "--register" {
		register = true
		args = args[1:]
	}

	if len(args) < 3 {
		fmt.Println("Usage: generate_all_protocols [--register] <protocol1,protocol2,...> <executable_path> <output_directory>")
		os.Exit(1)
	}

	protocols := strings.Split(args[0], ",")
	execPath, _ := filepath.Abs(args[1])
	outputDir := args[2]

	for i := range protocols {
		protocols[i] = strings.TrimSpace(protocols[i])
	}

	generateWindows(protocols, execPath, outputDir)
	generateLinux(protocols, execPath, outputDir)
	generateMac(protocols, outputDir)

	if register {
		if err := registerProtocols(outputDir); err != nil {
			fmt.Printf("❌ Registration failed: %v\n", err)
		} else {
			fmt.Println("✅ Protocols registered successfully")
		}
	}
}

func registerProtocols(outputDir string) error {
	// Note: Actual registration would require platform-specific code and permissions.
	// This is a placeholder to indicate where such logic would go.
	switch osType := strings.ToLower(os.Getenv("OS")); {
	case strings.Contains(osType, "windows"):
		// Look into the folder and import .reg files
		files, err := os.ReadDir(outputDir)
		if err != nil {
			return err
		}

		for _, file := range files {
			if strings.HasSuffix(file.Name(), ".reg") {
				filePath := filepath.Join(outputDir, file.Name())
				cmd := fmt.Sprintf("reg import \"%s\"", filePath)
				if err := executeCommand(cmd); err != nil {
					return err
				}
			}
		}
	case strings.Contains(osType, "linux"):
		// Linux registration would typically involve xdg-mime commands
		files, err := os.ReadDir(outputDir)
		if err != nil {
			return err
		}
		for _, file := range files {
			if strings.HasSuffix(file.Name(), ".desktop") {
				filePath := filepath.Join(outputDir, file.Name())
				cmd := fmt.Sprintf("xdg-desktop-menu install --novendor \"%s\"", filePath)
				if err := executeCommand(cmd); err != nil {
					return err
				}
			}
		}
	default:
		return fmt.Errorf("unsupported OS for registration: %s", osType)
	}

	return fmt.Errorf("environment variable for OS wasn't set, thus no OS detection")
}

func executeCommand(cmd string) error {
	var execCmd *exec.Cmd

	if runtime.GOOS == "windows" {
		execCmd = exec.Command("cmd", "/C", cmd)
	} else {
		execCmd = exec.Command("sh", "-c", cmd)
	}

	return execCmd.Run()
}

// 🪟 WINDOWS (.reg)
func generateWindows(protocols []string, execPath string, outputDir string) {
	for _, protocol := range protocols {
		fileName := fmt.Sprintf("%s/custom_protocol-%s.reg", outputDir, protocol)
		content := fmt.Sprintf(`Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Classes\%[1]s]
@="URL:%[1]s Protocol"
"URL Protocol"=""

[HKEY_CURRENT_USER\Software\Classes\%[1]s\shell]

[HKEY_CURRENT_USER\Software\Classes\%[1]s\shell\open]

[HKEY_CURRENT_USER\Software\Classes\%[1]s\shell\open\command]
@="\"%[2]s\" \"%%1\""
`, protocol, execPath)

		if err := os.WriteFile(fileName, []byte(content), 0644); err != nil {
			fmt.Printf("❌ Failed to write %s: %v\n", fileName, err)
			continue
		}
		fmt.Printf("✅ Created %s\n", fileName)
	}
}

// 🐧 LINUX (.desktop)
func generateLinux(protocols []string, execPath string, outputDir string) {
	for _, protocol := range protocols {
		fileName := fmt.Sprintf("%s/custom_protocol-%s.desktop", outputDir, protocol)
		content := fmt.Sprintf(`[Desktop Entry]
Name=%[1]s
Exec=%[2]s %%u
Type=Application
MimeType=x-scheme-handler/%[1]s;
NoDisplay=true
`, protocol, execPath)

		if err := os.WriteFile(fileName, []byte(content), 0644); err != nil {
			fmt.Printf("❌ Failed to write %s: %v\n", fileName, err)
			continue
		}
		fmt.Printf("✅ Created %s\n", fileName)
	}
}

// 🍎 MACOS (.plist)
func generateMac(protocols []string, outputDir string) {
	fileName := fmt.Sprintf("%s/custom_protocols.plist", outputDir)

	var plistEntries strings.Builder
	for _, protocol := range protocols {
		plistEntries.WriteString(fmt.Sprintf(`
    <dict>
        <key>CFBundleURLName</key>
        <string>com.example.%[1]s</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>%[1]s</string>
        </array>
    </dict>
`, protocol))
	}

	content := fmt.Sprintf(`<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleURLTypes</key>
    <array>
	%s
    </array>
</dict>
</plist>
`, plistEntries.String())

	if err := os.WriteFile(fileName, []byte(content), 0644); err != nil {
		fmt.Printf("❌ Failed to write %s: %v\n", fileName, err)
		return
	}

	fmt.Printf("✅ Created %s (includes %d protocols)\n", fileName, len(protocols))
}
