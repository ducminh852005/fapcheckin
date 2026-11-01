import json, os
from pathlib import Path
import pytest

@pytest.fixture
def android(request):
    if not os.getenv('ANDROID_E2E_CONFIG'):
        pytest.skip('ANDROID_E2E_CONFIG required: real device, seeded account and selectors')
    from appium import webdriver
    from appium.options.android import UiAutomator2Options
    config = json.loads(Path(os.environ['ANDROID_E2E_CONFIG']).read_text(encoding='utf-8'))
    driver = webdriver.Remote(config.get('server', 'http://127.0.0.1:4723'), options=UiAutomator2Options().load_capabilities(config['capabilities']))
    yield driver, config
    out = Path(__file__).parent / 'results' / os.getenv('E2E_RUN_ID', 'local')
    out.mkdir(parents=True, exist_ok=True)
    driver.save_screenshot(str(out / (request.node.name + '.png')))
    (out / (request.node.name + '.xml')).write_text(driver.page_source, encoding='utf-8')
    driver.quit()
