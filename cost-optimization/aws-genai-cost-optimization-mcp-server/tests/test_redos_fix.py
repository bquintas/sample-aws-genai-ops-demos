"""Test that ReDoS vulnerability is fixed.

This test ensures that the regex patterns in bedrock_detector.py are protected
against Regular Expression Denial of Service (ReDoS) attacks while maintaining
correct functionality for legitimate input.

Security Issue Fixed:
- BedrockModel pattern: r'BedrockModel\s*\(((?:[^()]*|\([^()]*\))*)\)'
- System prompt pattern: r'system_prompt\s*=\s*\(((?:[^()]*|\([^()]*\))*)\)'

Both patterns used nested quantifiers that could cause exponential backtracking
on malicious input with many nested parentheses.
"""
import sys
sys.path.insert(0, 'src')
import time
from mcp_cost_optim_genai.detectors.bedrock_detector import BedrockDetector

def test_redos_protection():
    """Test that malicious input doesn't cause exponential backtracking."""
    detector = BedrockDetector()
    
    # Malicious input that would cause ReDoS with the old patterns
    malicious_bedrock = "BedrockModel(" + "(" * 50 + "test" + ")" * 50
    malicious_system_prompt = "system_prompt=(" + "(" * 50 + "test" + ")" * 50
    
    print("Testing ReDoS protection...")
    print(f"Malicious BedrockModel input length: {len(malicious_bedrock)}")
    print(f"Malicious system_prompt input length: {len(malicious_system_prompt)}")
    
    # Test BedrockModel pattern
    start_time = time.time()
    findings1 = detector._detect_strands_bedrock_model(malicious_bedrock, "test.py")
    bedrock_time = time.time() - start_time
    
    # Test system_prompt pattern  
    start_time = time.time()
    analysis = detector._analyze_system_prompt_staticness(malicious_system_prompt)
    prompt_time = time.time() - start_time
    
    print(f"\nBedrockModel pattern processing time: {bedrock_time:.4f} seconds")
    print(f"System prompt pattern processing time: {prompt_time:.4f} seconds")
    
    # Both should complete quickly (< 1 second for safety, < 0.1s expected)
    MAX_PROCESSING_TIME = 1.0  # Conservative threshold
    
    if bedrock_time < MAX_PROCESSING_TIME and prompt_time < MAX_PROCESSING_TIME:
        print("\n✅ ReDoS protection working! Both patterns completed quickly.")
        print("✅ Malicious input did not cause exponential backtracking.")
        return True
    else:
        print(f"\n❌ ReDoS protection failed! Processing took too long.")
        print(f"❌ BedrockModel: {bedrock_time:.4f}s, System prompt: {prompt_time:.4f}s")
        return False

def test_legitimate_input_still_works():
    """Test that legitimate input still works correctly."""
    detector = BedrockDetector()
    
    # Legitimate BedrockModel usage
    legitimate_bedrock = '''
bedrock_model = BedrockModel(
    model_id="anthropic.claude-3-sonnet-20240229-v1:0",
    temperature=0.1,
    streaming=True
)
'''
    
    # Legitimate system_prompt usage
    legitimate_prompt = '''
agent = Agent(
    system_prompt=(
        "You are a helpful assistant. "
        "Provide clear answers. "
        "Use tools when needed."
    )
)
'''
    
    print("\nTesting legitimate input...")
    
    # Test BedrockModel detection
    findings = detector._detect_strands_bedrock_model(legitimate_bedrock, "test.py")
    bedrock_detected = len(findings) > 0
    
    # Test system_prompt detection
    analysis = detector._analyze_system_prompt_staticness(legitimate_prompt)
    prompt_detected = analysis.get('system_prompts_found', 0) > 0
    
    print(f"BedrockModel detected: {bedrock_detected}")
    print(f"System prompt detected: {prompt_detected}")
    
    if bedrock_detected and prompt_detected:
        print("✅ Legitimate patterns still detected correctly!")
        return True
    else:
        print("❌ Legitimate patterns not detected - regex fix broke functionality!")
        return False

if __name__ == "__main__":
    print("=" * 80)
    print("REDOS VULNERABILITY FIX TEST")
    print("=" * 80)
    
    redos_protected = test_redos_protection()
    legitimate_works = test_legitimate_input_still_works()
    
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    
    if redos_protected and legitimate_works:
        print("\n🎉 SUCCESS! ReDoS vulnerability fixed without breaking functionality!")
        print("✅ Malicious input processed quickly (no exponential backtracking)")
        print("✅ Legitimate patterns still detected correctly")
    else:
        print("\n❌ FAILURE! ReDoS fix has issues:")
        if not redos_protected:
            print("❌ Still vulnerable to ReDoS attacks")
        if not legitimate_works:
            print("❌ Broke legitimate pattern detection")