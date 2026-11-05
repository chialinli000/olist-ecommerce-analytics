import copy
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

import report


class ReportChecks(unittest.TestCase):
    def setUp(self):
        self.data, self.hashes = report.load_data(report.DEFAULT_DATA)

    def test_actual_august_comparison(self):
        facts = report.build_facts(self.data,'2018-08')
        delta = facts['facts'][1]['values']
        self.assertAlmostEqual(delta['order_change_pct'],100*(6512/6292-1))
        self.assertAlmostEqual(delta['cancellation_change_pp'],100*(84/6512-41/6292))
        self.assertEqual(facts['customer_snapshot'],'2018-09-01')

    def test_customer_snapshot_does_not_change_with_month(self):
        first = report.build_facts(self.data,'2017-01')
        last = report.build_facts(self.data,'2018-08')
        self.assertEqual(first['facts'][2:4],last['facts'][2:4])
        self.assertIn('not calculated',first['facts'][1]['text'])

    def test_missing_previous_month_is_not_bridged(self):
        self.data['monthly_performance'] = [r for r in self.data['monthly_performance'] if r['order_month']!='2018-07']
        self.assertIn('not calculated',report.build_facts(self.data,'2018-08')['facts'][1]['text'])

    def test_duplicate_month_rejected(self):
        self.data['monthly_performance'].append(copy.deepcopy(self.data['monthly_performance'][0]))
        with self.assertRaises(report.DataError): report.validate(self.data)

    def test_percent_unit_mistake_rejected(self):
        self.data['executive_kpis'][0]['cancellation_rate_pct'] = 63
        with self.assertRaises(report.DataError): report.validate(self.data)

    def test_customer_count_mismatch_rejected(self):
        self.data['customer_frequency'][0]['customer_count'] += 1
        with self.assertRaises(report.DataError): report.validate(self.data)

    def test_segment_value_mismatch_rejected(self):
        self.data['customer_segments'][0]['avg_customer_value'] = 999
        with self.assertRaises(report.DataError): report.validate(self.data)

    def test_unknown_month_rejected(self):
        with self.assertRaises(report.DataError): report.build_facts(self.data,'2026-11')

    def test_ai_unknown_evidence_rejected(self):
        p = report.build_facts(self.data)
        draft = report.offline_draft(p)
        draft['insights'][0]['fact_ids'] = ['invented']
        with self.assertRaises(report.DataError): report.check_draft(draft,p)

    def test_ai_new_numbers_rejected(self):
        p = report.build_facts(self.data)
        draft = report.offline_draft(p)
        draft['insights'][0]['explanation'] = 'Revenue increased by 99%'
        with self.assertRaises(report.DataError): report.check_draft(draft,p)

    def test_api_request_and_response_with_mock(self):
        payload = report.build_facts(self.data)
        result = report.offline_draft(payload)
        response = {'status':'completed','output':[{'type':'message','content':[{'type':'output_text','text':json.dumps(result)}]}]}
        with patch.dict('os.environ',{'OPENAI_API_KEY':'test-only'}), patch('urllib.request.urlopen') as fetch:
            import io
            fetch.return_value.__enter__.return_value = io.StringIO(json.dumps(response))
            actual, _ = report.ai_draft(payload,'test-model')
            self.assertEqual(result,actual)
            body = json.loads(fetch.call_args.args[0].data)
            self.assertFalse(body['store'])
            self.assertEqual(body['text']['format']['type'],'json_schema')

    def test_offline_creates_report_without_network(self):
        with tempfile.TemporaryDirectory(dir=report.ROOT) as folder, patch('urllib.request.urlopen',side_effect=AssertionError('Offline must not call network')):
            args = SimpleNamespace(data=report.DEFAULT_DATA,output=Path(folder),month='2018-08',ai=False,model='')
            path = report.run(args)
            text = path.read_text(encoding='utf-8')
            self.assertIn('Offline rule-based summary | No AI call',text)
            self.assertIn('6,512',text)
            self.assertTrue((path.parent/'run.json').is_file())
            self.assertEqual(len(json.loads((path.parent/'run.json').read_text(encoding='utf-8'))['input_sha256']),6)


if __name__=='__main__':
    unittest.main()
