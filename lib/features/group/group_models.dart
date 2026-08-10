import '../../shared/format.dart';

/// Tóm tắt một nhóm (khớp summary() ở GroupApiController).
class GroupSummary {
  final String token;
  final String? title;
  final int hotelId;
  final String hotelName;
  final String? checkIn;
  final String? checkOut;
  final bool organizer;
  final String? status;
  final bool ended;

  GroupSummary({
    required this.token,
    this.title,
    required this.hotelId,
    required this.hotelName,
    this.checkIn,
    this.checkOut,
    this.organizer = false,
    this.status,
    this.ended = false,
  });

  factory GroupSummary.fromJson(Map<String, dynamic> j) => GroupSummary(
        token: (j['token'] ?? '') as String,
        title: j['title'] as String?,
        hotelId: asNum(j['hotelId'])?.toInt() ?? 0,
        hotelName: (j['hotelName'] ?? '') as String,
        checkIn: j['checkIn']?.toString(),
        checkOut: j['checkOut']?.toString(),
        organizer: j['organizer'] == true,
        status: j['status'] as String?,
        ended: j['ended'] == true,
      );

  String get displayTitle => (title != null && title!.isNotEmpty) ? title! : hotelName;
}

class GroupMember {
  final String name;
  final int? userId;
  final int rooms;
  final num? amount;
  final String status;
  final String bookingCode;
  final bool mine;
  GroupMember(
      {required this.name,
      this.userId,
      this.rooms = 1,
      this.amount,
      required this.status,
      required this.bookingCode,
      this.mine = false});
  factory GroupMember.fromJson(Map<String, dynamic> j) => GroupMember(
        name: (j['name'] ?? 'Khách') as String,
        userId: asNum(j['userId'])?.toInt(),
        rooms: asNum(j['rooms'])?.toInt() ?? 1,
        amount: asNum(j['amount']),
        status: (j['status'] ?? '') as String,
        bookingCode: (j['bookingCode'] ?? '') as String,
        mine: j['mine'] == true,
      );
  bool get paid => status == 'CONFIRMED';
}

class GroupRoomType {
  final int id;
  final String name;
  final num? basePrice;
  GroupRoomType({required this.id, required this.name, this.basePrice});
  factory GroupRoomType.fromJson(Map<String, dynamic> j) => GroupRoomType(
        id: asNum(j['id'])?.toInt() ?? 0,
        name: (j['name'] ?? '') as String,
        basePrice: asNum(j['basePrice']),
      );
}

class GroupDetail {
  final GroupSummary group;
  final List<GroupMember> members;
  final int memberCount;
  final int paidCount;
  final num totalAll;
  final num totalPaid;
  final List<GroupRoomType> roomTypes;
  final bool closed;
  final bool joinable;

  GroupDetail({
    required this.group,
    this.members = const [],
    this.memberCount = 0,
    this.paidCount = 0,
    this.totalAll = 0,
    this.totalPaid = 0,
    this.roomTypes = const [],
    this.closed = false,
    this.joinable = true,
  });

  factory GroupDetail.fromJson(Map<String, dynamic> j) => GroupDetail(
        group: GroupSummary.fromJson(j),
        members: ((j['members'] as List?) ?? const [])
            .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
            .toList(),
        memberCount: asNum(j['memberCount'])?.toInt() ?? 0,
        paidCount: asNum(j['paidCount'])?.toInt() ?? 0,
        totalAll: asNum(j['totalAll']) ?? 0,
        totalPaid: asNum(j['totalPaid']) ?? 0,
        roomTypes: ((j['roomTypes'] as List?) ?? const [])
            .map((e) => GroupRoomType.fromJson(e as Map<String, dynamic>))
            .toList(),
        closed: j['closed'] == true,
        joinable: j['joinable'] == true,
      );
}
