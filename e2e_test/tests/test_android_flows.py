import pytest

CASES = ['TC01_google_signin', 'TC02_invalid_role', 'TC03_create_session',
         'TC04_display_qr', 'TC05_history', 'TC06_filter_subject',
         'TC07_export_report', 'TC08_pending_request', 'TC09_error_state',
         'TC10_native_popup']

@pytest.mark.parametrize('case_id', CASES)
def test_android_flow(android, case_id):
    from appium.webdriver.common.appiumby import AppiumBy
    from selenium.webdriver.support.ui import WebDriverWait
    from selenium.webdriver.support import expected_conditions as EC
    driver, config = android
    # Missing flows fail explicitly. Configure real native accessibility IDs or XPath.
    flow = config['flows'][case_id]
    assert flow['steps'], 'A flow needs actions and a fresh, documented initial state'
    by = {'id': AppiumBy.ID, 'accessibility id': AppiumBy.ACCESSIBILITY_ID, 'xpath': AppiumBy.XPATH}
    wait = WebDriverWait(driver, config.get('timeout', 20))
    for step in flow['steps']:
        locator = (by[step['by']], step['value'])
        action = step['action']
        if action == 'tap': wait.until(EC.element_to_be_clickable(locator)).click()
        elif action == 'type':
            el = wait.until(EC.visibility_of_element_located(locator))
            el.clear(); el.send_keys(step['text'])
        else: raise ValueError('Unsupported action: ' + action)
    expected = flow['expected']
    el = wait.until(EC.visibility_of_element_located((by[expected['by']], expected['value'])))
    assert expected['text'] in el.text
