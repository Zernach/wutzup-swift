#!/usr/bin/env python3
"""Kill meaningful queue/privacy mutants in disposable copies; never edit the checkout."""
from pathlib import Path
import os
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = root / 'Wutzup/Services/Local/OfflineMessageQueue.swift'
original = source.read_text()
mutations = [
    ('stale sender accepted', 'message.senderId == actorID,', 'true,', 'A stale enqueue cannot enter another account queue'),
    ('shared account partition', '"wutzup.offlineMessageQueue.v2." + $0', '"wutzup.offlineMessageQueue.v2.shared" + String($0.prefix(0))', "The previous owner's unacknowledged messages are retained for safe replay"),
    ('late account continuation', 'session == generation, self.actorID == actorID', 'true', 'Account change stops the rest of the old batch'),
    ('unbounded retry boundary', 'message.retryCount >= 5', 'message.retryCount >= 6', 'The fifth failure reaches the bounded failed state'),
    ('lost acknowledgement persistence', '            persist()\n            do { try await Task.sleep', '            pendingCount = pendingMessages.count\n            do { try await Task.sleep', 'Acknowledged sends cannot reappear after process death'),
]
with tempfile.TemporaryDirectory(prefix='wutzup-queue-mutations-') as directory:
    temporary = Path(directory)
    for name, before, after, evidence in mutations:
        assert before in original, f'Mutation anchor drifted: {name}'
        copy = temporary / 'OfflineMessageQueue.swift'
        copy.write_text(original.replace(before, after))
        binary = temporary / 'queue-test'
        subprocess.run(['swiftc', '-parse-as-library', str(copy),
            str(root/'Wutzup/Services/Protocols/MessageService.swift'),
            str(root/'Wutzup/Models/Domain/Message.swift'),
            str(root/'Wutzup/Utilities/DraftManager.swift'),
            str(root/'tests/OfflineQueueTests.swift'), '-o', str(binary)], check=True, capture_output=True)
        result = subprocess.run([str(binary)], capture_output=True, env={**os.environ, 'SWIFT_BACKTRACE':'disable'}, timeout=30)
        assert result.returncode != 0 and evidence in result.stderr.decode(errors='replace'), f'Meaningful mutant survived or failed for an unrelated reason: {name}'
        print(f'Killed: {name}')
print(f'{len(mutations)}/{len(mutations)} meaningful queue mutants killed')
