# Fix MCPToolController#listTools

## Problem

MCPToolController#listTools does not currently return the complete set of available tools. As a result, some tools are missing from its output.

## Solution

Review MCPToolController#callTools to determine how available tools are identified, then update listTools so it returns the full and correct tool list.
