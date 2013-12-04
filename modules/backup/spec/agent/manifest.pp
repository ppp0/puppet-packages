node default {

  backup::agent {'my-lvm':
    sourceType => 'lvm',
    host => 'localhost',
    source => '/dev/vg01/storage01',
    destination => '/home/backup/shared',
    options => '--no-eas --no-file-statistics --no-carbonfile --no-acls --no-compare-inode',
    cronTimeMinute => 30,
    cronTimeHour => 8,
  }

  backup::agent {'my-mysql':
    sourceType => 'mysql',
    host => 'localhost',
    source => '/var/lib/mysql',
    destination => '/home/backup/db',
    options => '--no-eas --no-file-statistics --no-carbonfile --no-acls --no-compare-inode',
    cronTimeMinute => 10,
    cronTimeHour => 5,
  }

}