import json, os
from pathlib import Path
import pytest


def _load_local_env():
    path = Path(__file__).parent / '.env.local'
    if not path.exists():
        return
    for raw_line in path.read_text(encoding='utf-8').splitlines():
        line = raw_line.strip()
        if not line or line.startswith('#') or '=' not in line:
            continue
        key, value = line.split('=', 1)
        os.environ.setdefault(key.strip(), value.strip())


_load_local_env()


@pytest.fixture
def android(request):
    if not os.getenv('ANDROID_E2E_CONFIG'):
        pytest.skip('ANDROID_E2E_CONFIG required: real device, seeded account and selectors')
    from appium import webdriver
    from appium.options.android import UiAutomator2Options
    config = json.loads(Path(os.environ['ANDROID_E2E_CONFIG']).read_text(encoding='utf-8'))
    case_id = request.node.callspec.params.get('case_id')
    flow = config.get('flows', {}).get(case_id, {})
    capabilities = dict(config['capabilities'])
    if flow.get('clearAppData'):
        capabilities['appium:noReset'] = False
    driver = webdriver.Remote(
        config.get('server', 'http://127.0.0.1:4723'),
        options=UiAutomator2Options().load_capabilities(capabilities),
    )
    yield driver, config
    out = Path(__file__).parent / 'results' / os.getenv('E2E_RUN_ID', 'local')
    out.mkdir(parents=True, exist_ok=True)
    driver.save_screenshot(str(out / (request.node.name + '.png')))
    (out / (request.node.name + '.xml')).write_text(driver.page_source, encoding='utf-8')
    driver.quit()
