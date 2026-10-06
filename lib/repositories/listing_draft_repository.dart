import '../models/listing_draft.dart';
import '../database/app_database.dart';

abstract class ListingDraftRepository {
  Future<void> saveDraft(ListingDraft draft, String imagePath);

  Future<List<ListingDraftRow>> getAllDrafts();

  Future<void> deleteDraft(int id);
}
